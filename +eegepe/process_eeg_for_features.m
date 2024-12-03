function y = process_eeg_for_features(x)
% f = @(x) [diff(x), 0];  % y[n] = x[n] - x[n-1]
% y = f(x);
y = [diff(x), 0];
end
