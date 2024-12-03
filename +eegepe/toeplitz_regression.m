function [real_weights, imag_weights] = toeplitz_regression(features, phase, n_f)
% Toeplitz regression to map features to real and imaginary parts of phase
% Inputs:
%   features - Backwards difference signal (input signal)
%   phase    - Angular phase (in radians, target signal)
%   n_f      - Filter length (number of taps)
% Outputs:
%   real_weights   - Learned weights for the real part of the analytic signal
%   imag_weights   - Learned weights for the imaginary part of the analytic signal

% Ensure features and phase have consistent lengths
features = features(:);  % Convert to column vector
phase = phase(:);        % Convert to column vector

% Construct Toeplitz matrix
T = toeplitz(features, [features(1); zeros(n_f-1, 1)]);

% Target signals: Real (cos) and imaginary (sin) parts of the analytic signal
target = [cos(phase), sin(phase)];

% deal with incomplete data
case_finite = any(isfinite(T), 2) & any(isfinite(target), 2);
case_finite(1:n_f - 1) = false;
T = T(case_finite, :);
target = target(case_finite, :);

% Solve for weights using linear regression
real_weights = (T' * T) \ (T' * target(:, 1));
imag_weights = (T' * T) \ (T' * target(:, 2));

end