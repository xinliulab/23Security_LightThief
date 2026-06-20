function res = decode_bits(rec_bits, p, n_bytes)
%DECODE_BITS  Coding-layer decode of the recovered OWC bit stream (paper Sec. 5.3, 6).
%   Cross-correlates the preamble to find frame start and resolve the BPSK
%   0/pi (180-degree) ambiguity, then decodes each 13-bit codeword with
%   Hamming(12,8) syndrome correction + overall-parity check into a byte.
%   (No Manchester decode step: selecting the m=1 reflected harmonic already
%   demodulates the Manchester/BPSK line code into bits.)
%
%   Returns a struct: bytes, text, n_frames, corrections, parity_ok, inverted, start.

if nargin < 2 || isempty(p), p = lt_params(); end
if nargin < 3, n_bytes = []; end

[start, invert] = find_frame_start(rec_bits, p.preamble);
if invert
    rec_bits = 1 - rec_bits;
end
payload = rec_bits(start + 1:end);          % start is 0-based -> +1 for MATLAB slice

L = p.code_len;
n_words = floor(numel(payload) / L);
bytes = [];
corrections = 0;
parity_ok = [];
for k = 0:n_words - 1
    codeword = payload(k * L + 1:(k + 1) * L);   % 13-bit codeword
    [byte, corrected, pok] = hamming_decode(codeword);
    bytes(end + 1) = byte;                       %#ok<AGROW>
    corrections = corrections + corrected;
    parity_ok(end + 1) = pok;                    %#ok<AGROW>
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
