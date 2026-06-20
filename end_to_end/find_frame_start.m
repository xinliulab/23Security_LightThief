function [start, invert] = find_frame_start(chips, preamble)
%FIND_FRAME_START  Correlate the preamble to find the (0-based) start after it.
%   INVERT is true when the recovered stream is the bit-complement (BPSK pi
%   ambiguity), in which case the caller should flip all chips.

if nargin < 2, preamble = [1 1 1 1 0 0 0 0]; end

c = 2 * chips - 1;                      % {0,1} -> {-1,+1}
p = 2 * preamble - 1;
corr = conv(c, fliplr(p), 'valid');    % cross-correlation (peak at alignment)
[~, best] = max(abs(corr));            % 1-based index
invert = corr(best) < 0;
start = (best - 1) + numel(preamble);  % 0-based offset after the preamble
end
