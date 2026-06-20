function h = hamming_12_8(byte)
%HAMMING_12_8  12-bit Hamming code for one byte (1-based positions).
%   Data bits sit at positions [3 5 6 7 9 10 11 12] (MSB-first); parity bits at
%   1,2,4,8 use the same coverage masks as the MATLAB implementation.  Mirrors
%   encoder.py / bpskPacketGenerator.m.

bits = double(bitget(uint8(byte), 8:-1:1));   % MSB first: bits(1) = bit 8
h = zeros(1, 12);
h([3 5 6 7 9 10 11 12]) = bits;

h(1) = mod(sum(h([3 5 7 9 11])), 2);
h(2) = mod(sum(h([3 6 7 10 11])), 2);
h(4) = mod(sum(h([5 6 7 12])), 2);
h(8) = mod(sum(h([9 10 11 12])), 2);
end
