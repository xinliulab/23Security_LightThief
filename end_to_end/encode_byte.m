function codeword = encode_byte(byte)
%ENCODE_BYTE  One byte -> 13-bit codeword (paper Sec. 6).
%   8-bit ASCII -> 12-bit Hamming(12,8) -> append 1 overall parity bit = 13 bits.
%   Manchester coding is NOT applied here: it is a line-coding/modulation step
%   applied when the optical waveform is built (see optical_waveform.m), because
%   in LightThief the Manchester square wave IS the transmitted optical signal.

h = hamming_12_8(byte);
overall_parity = mod(sum(h), 2);
codeword = [h, overall_parity];      % 13-bit extended-Hamming codeword
end
