function best_phase = estimate_timing_phase(x, sps, step)
%ESTIMATE_TIMING_PHASE  Fractional symbol-timing phase maximizing mean |sample|.
%   At the correct phase the symbol-spaced samples sit on the half-sine pulse
%   peaks; off-phase they fall on inter-symbol transitions.  Robust for this
%   NRZ-style signal and absorbs the matched-filter delay and static timing offset.

if nargin < 2, sps = 4; end
if nargin < 3, step = 0.05; end

base = 0:sps:(numel(x) - sps - 1);
best_phase = 0;
best_metric = -1;
for ph = 0:step:(sps - step)
    samp = interp_samples(x, ph + base);
    m = mean(abs(samp));
    if m > best_metric
        best_metric = m;
        best_phase = ph;
    end
end
end
