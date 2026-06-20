function out = symbol_sync(x, sps)
%SYMBOL_SYNC  Timing recovery -> one complex sample per symbol at estimated phase.

if nargin < 2, sps = 4; end
ph = estimate_timing_phase(x, sps);
base = 0:sps:(numel(x) - sps - 1);
out = interp_samples(x, ph + base);
end
