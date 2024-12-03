function [phase] = process_eeg_for_target(eeg_signal, fs, bp_filter_order, passband, t_future, acausal)
% Function to process EEG signal into features and phase for analysis
% Inputs:
%   eeg_signal - Raw EEG signal (1 x N vector)
%   fs         - Sampling rate (in Hz)
%   bp_filter_order - bandpass filter order (taps)
%   t_future - how many seconds to predict into future (defualt: 0)
%   acausal - whether to process acausally or not - should be true for most uses
% Outputs:
%   features - Features derived from the backwards difference (vector)
%   phase    - Angular phase derived from the analytic signal (vector)

%%
if nargin < 6
    acausal = true;
end
if nargin < 5
    t_future = 0;
end

assert(all([size(eeg_signal, 1) == 1, size(eeg_signal, 2) > 1]), 'Expecting a 1 x N signal.');

%% Branch 2: Bandpass Filtering and Hilbert Transform for Phase
% Design FIR Bandpass Filter (8-12 Hz, order 769, Hamming window)
nyquist = fs / 2;
fir_coeff = fir1(bp_filter_order, passband / nyquist, 'bandpass', hamming(bp_filter_order + 1));

% Apply bandpass filter
if acausal
    filtered_signal = filtfilt(fir_coeff, 1, eeg_signal);
else
    % not sure if this is perfect...
    filtered_signal = filter(fir_coeff, 1, eeg_signal);
    % Compensate for the group delay
    group_delay = bp_filter_order / 2;
    ix_original = (0:length(filtered_signal)-1)';
    ix_shifted = ix_original + group_delay;
    filtered_signal = interp1(ix_original, filtered_signal, ix_shifted, 'linear', 'extrap');
end

% Compute analytic signal using Hilbert transform
analytic_signal = hilbert(filtered_signal);

% Normalize analytic signal to generate complex representation of phase
complex_phase = analytic_signal ./ abs(analytic_signal);

% Convert to angular phase (in radians)
phase = angle(complex_phase);

% shift the target vector if you want to predict beyond future time
% (beyond instantaneous phase)
n_shift = round(t_future * fs);
phase = circshift(phase, -n_shift);
phase(end-n_shift:end) = nan;

end