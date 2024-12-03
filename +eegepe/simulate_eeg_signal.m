function [phase_gt, eeg_signal] = simulate_eeg_signal(t, fs, f_central, f_jitter_strength)
% Function to generate an EEG signal with pink noise and a 10 Hz oscillation
% saving the underlying information regarding the ground truth phase.
% Inputs:
%   t  - Time vector (in seconds)
%   fs - Sampling rate (in Hz)
% Outputs:
%   phase_gt   - Phase of the 10 Hz oscillation (in radians)
%   eeg_signal - Simulated EEG signal (in μV)

% Total number of samples
N = length(t);

% Generate pink noise
white_noise = randn(1, N);
f_white = fft(white_noise);
frequencies = (0:(N/2)) / (N/fs);  % Positive frequencies
S = ones(size(frequencies));
S(2:end) = 1 ./ sqrt(frequencies(2:end));  % Scale for pink noise (1/√f)
S_full = [S, fliplr(S(2:end-1))];  % Mirror to create full spectrum
f_pink = f_white .* S_full;  % Apply pink noise scaling
pink_noise = ifft(f_pink, 'symmetric');
pink_noise = (pink_noise - mean(pink_noise)) / std(pink_noise) * 20;  % Scale to 20 μV std dev

% Generate oscillation around central frequenuency with jitter
freq_jitter = randn(1, N);
sigma = fs * 0.1;  % Smoothing factor (corresponds to 0.1 sec)
freq_jitter = smoothdata(freq_jitter, 'gaussian', sigma);
freq_jitter = freq_jitter / std(freq_jitter) * f_jitter_strength;  % Scale jitter
inst_freq = f_central + freq_jitter;  % Instantaneous frequency in Hz
phase_gt = wrapToPi(2 * pi * cumsum(inst_freq) / fs);
oscillation = cos(phase_gt);
oscillation = oscillation / std(oscillation) * 10;  % Scale to 10 μV std dev

% Combine signals
eeg_signal = pink_noise + oscillation;
end