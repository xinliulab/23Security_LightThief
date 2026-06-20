function [byte, corrected, parity_ok] = hamming_decode(codeword)
%HAMMING_DECODE  Decode one 13-bit extended-Hamming codeword.
%   codeword(1:12) are Hamming positions 1..12; codeword(13) is overall parity.
%   Returns the byte, whether a single-bit error was corrected, and parity check.

r = codeword(1:12);

sets = {[1 3 5 7 9 11], [2 3 6 7 10 11], [4 5 6 7 12], [8 9 10 11 12]};
weights = [1 2 4 8];
syndrome = 0;
for i = 1:4
    bit = mod(sum(r(sets{i})), 2);
    syndrome = syndrome + weights(i) * bit;
end

corrected = false;
if syndrome >= 1 && syndrome <= 12
    r(syndrome) = 1 - r(syndrome);      % flip the single bit error
    corrected = true;
end

parity_ok = (mod(sum(r), 2) == codeword(13));

data_positions = [3 5 6 7 9 10 11 12];
byte = 0;
for pos = data_positions                % MSB-first reassembly
    byte = byte * 2 + r(pos);
end
end
