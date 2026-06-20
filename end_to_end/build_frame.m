function [chips, truth] = build_frame(text, n_repeat, preamble)
%BUILD_FRAME  Chip-bit frame: preamble + n_repeat copies of the encoded text.
%   Returns the chip bits and the ground-truth byte values.

if nargin < 2 || isempty(n_repeat), n_repeat = 8; end
if nargin < 3 || isempty(preamble), preamble = [1 1 1 1 0 0 0 0]; end

payload = encode_text(text);
chips = [preamble, repmat(payload, 1, n_repeat)];
truth = double(text);
end
