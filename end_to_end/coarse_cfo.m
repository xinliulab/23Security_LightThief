function [out, f_cfo] = coarse_cfo(sig, fs)
%COARSE_CFO  Estimate+remove CFO via the BPSK 2nd-power FFT peak (tone at 2*f_cfo).

sq = sig .^ 2;
n = numel(sq);
spec = abs(fft(sq));
[~, k] = max(spec);
f_all = (0:n - 1) * (fs / n);
fk = f_all(k);
if fk >= fs / 2
    fk = fk - fs;                       % wrap to negative frequencies
end
f_cfo = fk / 2;

t = (0:n - 1) / fs;
out = sig .* exp(-1j * 2 * pi * f_cfo * t);
end
