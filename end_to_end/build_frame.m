function [frame_bits, truth] = build_frame(text, n_repeat, preamble)
%BUILD_FRAME  OWC frame at the BIT level: preamble + payload codewords.
%   frame_bits = [preamble, n_repeat copies of the 13-bit-codeword payload].
%   These bits are later Manchester-coded into the optical square wave.
%   Returns the frame bits and the ground-truth byte values.

if nargin < 2 || isempty(n_repeat), n_repeat = 8; end
if nargin < 3 || isempty(preamble), preamble = [1 1 1 1 0 0 0 0 1 0]; end  % paper "1111000010"

payload = encode_text(text);
frame_bits = [preamble, repmat(payload, 1, n_repeat)];
truth = double(text);
end
