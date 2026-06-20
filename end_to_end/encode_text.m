function bits = encode_text(text)
%ENCODE_TEXT  Concatenated 13-bit codewords for every character in TEXT.
%   Output is the payload bit stream (before Manchester line coding).

bytes = double(text);                  % code points (Latin-1, <=255)
bits = [];
for i = 1:numel(bytes)
    bits = [bits, encode_byte(bytes(i))]; %#ok<AGROW>
end
end
