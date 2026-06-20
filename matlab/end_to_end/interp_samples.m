function out = interp_samples(x, pos)
%INTERP_SAMPLES  Linear interpolation of x at 0-based fractional positions POS.
%   x is indexed 1-based in MATLAB, so a 0-based position p maps to x(p+1).

n = numel(x);
i0 = floor(pos);                        % 0-based left index
frac = pos - i0;
i1 = min(i0 + 1, n - 1);                % 0-based right index, clamped
out = x(i0 + 1) .* (1 - frac) + x(i1 + 1) .* frac;
end
