function bits = manchester_decode(chips)
%MANCHESTER_DECODE  IEEE 802.3 Manchester decode: [1 0]->1, [0 1]->0.
%   Uses both chips of each pair (first vs second) for small noise immunity.

chips = chips(1:end - mod(numel(chips), 2));
a = chips(1:2:end);
b = chips(2:2:end);
bits = double(a >= b);                  % ties default to 1
end
