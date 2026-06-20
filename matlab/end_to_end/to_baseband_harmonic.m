function bb = to_baseband_harmonic(chips, sps)
%TO_BASEBAND_HARMONIC  Complex baseband equivalent of one isolated harmonic.
%   Frequency-shifted backscatter only translates the data spectrum onto the
%   square wave's odd harmonics (fc +/- k*f_sw); after the receiver band-selects
%   and mixes one harmonic down, the envelope is exactly the data BPSK scaled by
%   that harmonic's Fourier weight 2/(pi*k) (k=1).  Modelled directly here for
%   the fast BER sweep; the literal comb is exercised by the passband path.

if nargin < 2, sps = 4; end
data = bpsk_pulse_shape(chips, sps);
harmonic_weight = 2 / pi;              % k=1 odd-harmonic amplitude of a +/-1 square
bb = complex(harmonic_weight * data);
end
