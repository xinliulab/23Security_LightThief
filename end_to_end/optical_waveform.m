function [chips, light] = optical_waveform(bits, samples_per_chip)
%OPTICAL_WAVEFORM  The data-coded optical signal = Manchester-coded OOK light.
%
%   Paper Sec. 3.2 / Fig. 4: OWC encodes each data bit with Manchester code and
%   transmits it as On-Off-Keyed (OOK) light intensity, giving a 50%-balanced
%   square wave at the optical clock rate f_o.  Manchester is essentially BPSK:
%   bit '1' -> light high-then-low (square-wave phase 0), bit '0' -> low-then-high
%   (phase pi).  This single light square wave is BOTH the transmitted data AND,
%   in LightThief, the On/Off control that switches the tag's reflection.
%
%   chips : the {0,1} Manchester chip stream (2 chips per bit) = light On/Off.
%   light : the chip stream sample-and-held at samples_per_chip (a hard optical
%           square wave) for plotting / driving the reflection.

if nargin < 2, samples_per_chip = 1; end
chips = manchester_enc(bits);                 % {0,1}, 2 per bit, balanced
light = repelem(chips, samples_per_chip);     % held square wave (light intensity)
end
