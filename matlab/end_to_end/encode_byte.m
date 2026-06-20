function chips = encode_byte(byte)
%ENCODE_BYTE  One byte -> 28 Manchester chip bits (the full MPDU for a char).
%   byte -> Hamming(12,8) -> +overall parity (13) -> +start bit (14) -> Manchester.

h = hamming_12_8(byte);
overall_parity = mod(sum(h), 2);
codeword = [h, overall_parity];        % 13 bits, extended Hamming
mpdu = [1, codeword];                  % 14 bits, start bit prepended
chips = manchester_enc(mpdu);          % 28 chips
end
