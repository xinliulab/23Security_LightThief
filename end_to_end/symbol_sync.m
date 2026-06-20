function out = symbol_sync(x, sps)
%SYMBOL_SYNC  Timing recovery -> one complex sample per symbol at estimated phase.

if nargin < 2, sps = 4; end
ph = estimate_timing_phase(x, sps);
base = 0:sps:(numel(x) - 1);
pos = ph + base;
pos = pos(pos <= numel(x) - 1);
out = interp_samples(x, pos);
end
