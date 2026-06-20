function out = matched_filter(sig, Nb)
%MATCHED_FILTER  Integrate-and-dump matched filter for the bit-rate BPSK.
%
%   The OWC bit is transmitted as one period of the optical square wave, so the
%   matched filter for the down-converted m=1 harmonic is a rectangular window
%   of one bit period (Nb baseband samples).  Integrating over exactly one bit
%   period also nulls the residual carrier leakage and the neighbouring
%   harmonics, which sit at integer multiples of the bit rate and are therefore
%   orthogonal over the symbol (this is what isolates the data sideband).

if nargin < 2, Nb = 20; end
h = ones(1, Nb) / Nb;                 % unit-area boxcar = integrate & dump
out = conv(sig, h, 'same');
end
