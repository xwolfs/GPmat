function [g1, g2] = lfmwhiteXlfmwhiteKernGradient(lfmKern1, lfmKern2, t1, varargin)

% LFMWHITEXLFMWHITEKERNGRADIENT Compute a cross gradient between two
% LFM-WHITE kernels.
% FORMAT
% DESC computes cross gradient of parameters of a cross kernel
% between two LFM-WHITE kernels for the multiple output kernel. 
% ARG lfmKern1 : the kernel structure associated with the first LFM-WHITE
% kernel.
% ARG lfmKern2 : the kernel structure associated with the second LFM-WHITE
% kernel.
% ARG t1 : inputs for which kernel is to be computed.
% ARG covGrad : gradient of the objective function with respect to
% the elements of the cross kernel matrix.
% RETURN g1 : gradient of the parameters of the first kernel, for
% ordering see lfmwhiteKernExtractParam.
% RETURN g2 : gradient of the parameters of the second kernel, for
% ordering see lfmwhiteKernExtractParam.
%
% FORMAT
% DESC computes cross kernel terms between two LFM-WHITE kernels for
% the multiple output kernel. 
% ARG lfmKern1 : the kernel structure associated with the first LFM-WHITE
% kernel.
% ARG lfmKern2 : the kernel structure associated with the second LFM-WHITE
% kernel.
% ARG t1 : row inputs for which kernel is to be computed.
% ARG t2 : column inputs for which kernel is to be computed.
% ARG covGrad : gradient of the objective function with respect to
% the elements of the cross kernel matrix.
% RETURN g1 : gradient of the parameters of the first kernel, for
% ordering see lfmwhiteKernExtractParam.
% RETURN g2 : gradient of the parameters of the second kernel, for
% ordering see lfmwhiteKernExtractParam.
%
% SEEALSO : multiKernParamInit, multiKernCompute, lfmwhiteKernParamInit,
% lfmwhiteKernExtractParam
%
% COPYRIGHT : David Luengo, 2009

% KERN


if nargin < 5
    t2 = t1;
else
    t2 = varargin{1};
end
covGrad = varargin{end};

if size(t1, 2) > 1 | size(t2, 2) > 1
  error('Input can only have one column');
end
if lfmKern1.variance ~= lfmKern2.variance
  error('Kernels cannot be cross combined if they have different variances.')
end

g1 = zeros(1, lfmKern1.nParams);
g2 = zeros(1, lfmKern1.nParams);

T1 = repmat(t1, 1, size(t2, 1));
T2 = repmat(t2.', size(t1, 1), 1);
ind = (T1 >= T2);

% Terms needed later in the gradients

mass1 = lfmKern1.mass;
spring1 = lfmKern1.spring;
damper1 = lfmKern1.damper;
sensitivity1 = lfmKern1.sensitivity;
alpha1 = lfmKern1.alpha;
omega1 = lfmKern1.omega;
gamma1 = lfmKern1.gamma;
gamma1Tilde = alpha1 - j*omega1;
isStationary1 = lfmKern1.isStationary;

mass2 = lfmKern2.mass;
spring2 = lfmKern2.spring;
damper2 = lfmKern2.damper;
sensitivity2 = lfmKern2.sensitivity;
alpha2 = lfmKern2.alpha;
omega2 = lfmKern2.omega;
gamma2 = lfmKern2.gamma;
gamma2Tilde = alpha2 - j*omega2;
isStationary2 = lfmKern2.isStationary;

variance = lfmKern1.variance;

c = variance * sensitivity1 * sensitivity2 ...
    / (4 * mass1 * mass2 * omega1 * omega2);
K = lfmwhiteXlfmwhiteKernCompute(lfmKern1, lfmKern2, t1, t2);

gradMass = [1 0 0];
gradAlpha1 = [-damper1/(2*mass1^2) 1/(2*mass1) 0];
gradAlpha2 = [-damper2/(2*mass2^2) 1/(2*mass2) 0];
c21 = sqrt(4*mass1*spring1-damper1^2);
gradOmega1 = [(damper1^2-2*mass1*spring1)/(2*c21*mass1^2) ...
    -damper1/(2*c21*mass1) 1/c21];
c22 = sqrt(4*mass2*spring2-damper2^2);
gradOmega2 = [(damper2^2-2*mass2*spring2)/(2*c22*mass2^2) ...
    -damper2/(2*c22*mass2) 1/c22];

% Gradient w.r.t. m_p and m_q
g1(1) = sum(sum(( c * (lfmwhiteComputeGradThetaH2(gamma2, gamma1Tilde, t1, t2, ...
        gradAlpha1(1) - j*gradOmega1(1), isStationary1, isStationary2) ...
    + lfmwhiteComputeGradThetaH2(gamma2Tilde, gamma1, t1, t2, ...
        gradAlpha1(1) + j*gradOmega1(1), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH2(gamma2Tilde, gamma1Tilde, t1, t2, ...
        gradAlpha1(1) - j*gradOmega1(1), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH2(gamma2, gamma1, t1, t2, ...
        gradAlpha1(1) + j*gradOmega1(1), isStationary1, isStationary2)) ...
    - (gradMass(1)/mass1 + gradOmega1(1)/omega1) * K) .* covGrad));
g2(1) = sum(sum(( c * (lfmwhiteComputeGradThetaH1(gamma2, gamma1Tilde, t1, t2, ...
        gradAlpha2(1) + j*gradOmega2(1), isStationary1, isStationary2) ...
    + lfmwhiteComputeGradThetaH1(gamma2Tilde, gamma1, t1, t2, ...
        gradAlpha2(1) - j*gradOmega2(1), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH1(gamma2Tilde, gamma1Tilde, t1, t2, ...
        gradAlpha2(1) - j*gradOmega2(1), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH1(gamma2, gamma1, t1, t2, ...
        gradAlpha2(1) + j*gradOmega2(1), isStationary1, isStationary2)) ...
    - (gradMass(1)/mass2 + gradOmega2(1)/omega2) * K) .* covGrad));

% Gradient w.r.t. D_p and D_q
g1(2) = sum(sum(( c * (lfmwhiteComputeGradThetaH2(gamma2, gamma1Tilde, t1, t2, ...
        gradAlpha1(3) - j*gradOmega1(3), isStationary1, isStationary2) ...
    + lfmwhiteComputeGradThetaH2(gamma2Tilde, gamma1, t1, t2, ...
        gradAlpha1(3) + j*gradOmega1(3), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH2(gamma2Tilde, gamma1Tilde, t1, t2, ...
        gradAlpha1(3) - j*gradOmega1(3), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH2(gamma2, gamma1, t1, t2, ...
        gradAlpha1(3) + j*gradOmega1(3), isStationary1, isStationary2)) ...
    - (gradMass(3)/mass1 + gradOmega1(3)/omega1) * K) .* covGrad));
g2(2) = sum(sum(( c * (lfmwhiteComputeGradThetaH1(gamma2, gamma1Tilde, t1, t2, ...
        gradAlpha2(3) + j*gradOmega2(3), isStationary1, isStationary2) ...
    + lfmwhiteComputeGradThetaH1(gamma2Tilde, gamma1, t1, t2, ...
        gradAlpha2(3) - j*gradOmega2(3), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH1(gamma2Tilde, gamma1Tilde, t1, t2, ...
        gradAlpha2(3) - j*gradOmega2(3), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH1(gamma2, gamma1, t1, t2, ...
        gradAlpha2(3) + j*gradOmega2(3), isStationary1, isStationary2)) ...
    - (gradMass(3)/mass2 + gradOmega2(3)/omega2) * K) .* covGrad));

% Gradient w.r.t. C_p and C_q
g1(3) = sum(sum(( c * (lfmwhiteComputeGradThetaH2(gamma2, gamma1Tilde, t1, t2, ...
        gradAlpha1(2) - j*gradOmega1(2), isStationary1, isStationary2) ...
    + lfmwhiteComputeGradThetaH2(gamma2Tilde, gamma1, t1, t2, ...
        gradAlpha1(2) + j*gradOmega1(2), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH2(gamma2Tilde, gamma1Tilde, t1, t2, ...
        gradAlpha1(2) - j*gradOmega1(2), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH2(gamma2, gamma1, t1, t2, ...
        gradAlpha1(2) + j*gradOmega1(2), isStationary1, isStationary2)) ...
    - (gradMass(2)/mass1 + gradOmega1(2)/omega1) * K) .* covGrad));
g2(3) = sum(sum(( c * (lfmwhiteComputeGradThetaH1(gamma2, gamma1Tilde, t1, t2, ...
        gradAlpha2(2) + j*gradOmega2(2), isStationary1, isStationary2) ...
    + lfmwhiteComputeGradThetaH1(gamma2Tilde, gamma1, t1, t2, ...
        gradAlpha2(2) - j*gradOmega2(2), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH1(gamma2Tilde, gamma1Tilde, t1, t2, ...
        gradAlpha2(2) - j*gradOmega2(2), isStationary1, isStationary2) ...
    - lfmwhiteComputeGradThetaH1(gamma2, gamma1, t1, t2, ...
        gradAlpha2(2) + j*gradOmega2(2), isStationary1, isStationary2)) ...
    - (gradMass(2)/mass2 + gradOmega2(2)/omega2) * K) .* covGrad));

% Gradient w.r.t. sigma_r^2
g1(4) = sum(sum(K .* covGrad)) / variance;
g2(4) = 0; % Otherwise it is counted twice

% Gradient w.r.t. S_{pr} and S_{qr}
g1(5) = sum(sum(K .* covGrad)) / sensitivity1;
g2(5) = sum(sum(K .* covGrad)) / sensitivity2;

% Ensuring that the gradients are real
g1 = real(g1);
g2 = real(g2);
