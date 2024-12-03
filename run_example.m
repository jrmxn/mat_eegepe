close all
clear;

%% Generate some fake data to demonstrate method
% (this is going to be the training signal)
fs = 512;  % Sampling rate in Hz
duration = 15;  % Duration in seconds
t = linspace(0, duration, fs * duration);  % Time vector
passband = [8 12];  % Passband in Hz for for filter prior to hilbert transform
f_central = 10;          % Central frequency in Hz
f_jitter_strength = 1.0; % Jitter strength in Hz

rng(0);
[phase_gt, eeg_signal] = eegepe.simulate_eeg_signal(t, fs, f_central, f_jitter_strength);

% Plot the EEG signal
figure;
plot(t, eeg_signal, 'b');
xlabel('Time (s)');
ylabel('Amplitude (μV)');
title('Simulated EEG Signal');
xlim([0, 2]);  % Display first 2 seconds
grid on;

% Compute and plot the power spectrum
[Pxx, f] = pwelch(eeg_signal, fs*2, [], [], fs);  % Welch's method
figure;
semilogy(f, Pxx, 'r');
xlabel('Frequency (Hz)');
ylabel('Power Spectral Density (μV²/Hz)');
title('Power Spectrum of Simulated EEG Signal');
xlim([0, 50]);
grid on;

%% Learn the filter weights to predict instantaneous phase causally
% Branch 1: Backwards Difference (to suppress electrode drift) for features
features = eegepe.process_eeg_for_features(eeg_signal);

% Branch 2: Generate the target phase that we want to learn from the features
bp_filter_order = round((fs * 1.5) + 1);
[phase] = eegepe.process_eeg_for_target(eeg_signal, fs, bp_filter_order, passband, fs);

% Learn the weights (filters)
n_f = 0.5 * fs;
[real_weights, imag_weights] = eegepe.toeplitz_regression(features, phase, n_f);

figure;
subplot(3, 1, 1);
plot(t, eeg_signal);
xlabel('Time (s)');
ylabel('Amplitude (μV)');
title('Original EEG Signal');

subplot(3, 1, 2);
plot(t, features);
xlabel('Time (s)');
ylabel('Amplitude');
title('Features');

subplot(3, 1, 3);
hold on;
h1 = plot(t, phase_gt, 'r');
h2 = plot(t, phase, 'b--');
h1.DisplayName = "Phase GT";
h2.DisplayName = "Phase target (acausal)";
xlabel('Time (s)');
ylabel('Phase (radians)');
legend([h1, h2])

figure;
subplot(2, 1, 1);
plot(real_weights, 'g', 'DisplayName', 'Real Weights');
title('Learned Weights for Real Part');
xlabel('Tap Index');
ylabel('Weight Value');
legend;

subplot(2, 1, 2);
plot(imag_weights, 'g', 'DisplayName', 'Imaginary Weights');
title('Learned Weights for Imaginary Part');
xlabel('Tap Index');
ylabel('Weight Value');
legend;

%% Now say we have some new data that we want to apply the filter weights too:
rng(1);  % different rng to training
[phase_gt_new, eeg_signal_new] = eegepe.simulate_eeg_signal(t, fs, f_central, f_jitter_strength);
features_new = eegepe.process_eeg_for_features(eeg_signal_new);
est_analytic = filter(real_weights, 1, features_new) + 1i * filter(imag_weights, 1, features_new);
phase_new = angle(est_analytic);
% bp_filter_order_short = round((fs * 0.22) + 1);

%
figure;
hold on;
plot(t, phase_gt_new, 'r', 'DisplayName', 'GT phase');
plot(t, phase_new, 'b--', 'DisplayName', 'Causal instantaneously recovered phase');

xlabel('Time (s)');
ylabel('Amplitude');
legend;
grid on;

%%





