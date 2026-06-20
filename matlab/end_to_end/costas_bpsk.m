function out = costas_bpsk(sym, kp, ki)
%COSTAS_BPSK  Decision-directed BPSK carrier phase / residual-frequency recovery.

if nargin < 2, kp = 0.05; end
if nargin < 3, ki = 2e-3; end

out = zeros(1, numel(sym));
phase = 0;
freq = 0;
for n = 1:numel(sym)
    v = sym(n) * exp(-1j * phase);
    out(n) = v;
    e = real(v) * imag(v);              % phase-error discriminant
    freq = freq + ki * e;
    phase = phase + freq + kp * e;
end
end
