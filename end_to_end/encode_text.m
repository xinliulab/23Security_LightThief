function chips = encode_text(text)
%ENCODE_TEXT  Concatenated 28-chip blocks for every character in TEXT.

bytes = double(text);                  % code points (Latin-1, <=255)
chips = [];
for i = 1:numel(bytes)
    chips = [chips, encode_byte(bytes(i))]; %#ok<AGROW>
end
end
