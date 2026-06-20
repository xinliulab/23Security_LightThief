function res = decode_chips(chips, preamble, n_bytes)
%DECODE_CHIPS  Full coding-layer decode of a recovered chip stream.
%   Returns a struct with fields: bytes, text, n_frames, corrections,
%   parity_ok, inverted, start.

if nargin < 2 || isempty(preamble), preamble = [1 1 1 1 0 0 0 0]; end
if nargin < 3, n_bytes = []; end

[start, invert] = find_frame_start(chips, preamble);
if invert
    chips = 1 - chips;
end
payload = chips(start + 1:end);         % start is 0-based -> +1 for MATLAB slice

chips_per_byte = 28;
n_blocks = floor(numel(payload) / chips_per_byte);
bytes = [];
corrections = 0;
parity_ok = [];
for k = 0:n_blocks - 1
    block = payload(k * chips_per_byte + 1:(k + 1) * chips_per_byte);
    mpdu = manchester_decode(block);    % 14 bits
    codeword = mpdu(2:end);             % drop start bit -> 13 bits
    [byte, corrected, pok] = hamming_decode(codeword);
    bytes(end + 1) = byte;              %#ok<AGROW>
    corrections = corrections + corrected;
    parity_ok(end + 1) = pok;           %#ok<AGROW>
    if ~isempty(n_bytes) && numel(bytes) >= n_bytes
        break;
    end
end

res = struct();
res.bytes = bytes;
res.text = char(bytes);
res.n_frames = numel(bytes);
res.corrections = corrections;
res.parity_ok = parity_ok;
res.inverted = invert;
res.start = start;
end
