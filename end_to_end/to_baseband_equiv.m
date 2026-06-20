function env = to_baseband_equiv(bits, p)
%TO_BASEBAND_EQUIV  Complex-baseband equivalent of the selected reflected harmonic.
%
%   Down-converting the m=1 reflected harmonic (fc+fo) and integrating over each
%   bit period recovers a bit-rate BPSK stream whose phase is theta_n (0 or pi)
%   -- i.e. the data bits themselves (Manchester is demodulated by selecting the
%   harmonic; paper Sec. 5.3).  This function produces that ideal complex
%   envelope directly, as NRZ +/-1 bit symbols at Nb samples/bit, for the fast
%   BER sweep.  The literal passband reflection + harmonic comb are produced by
%   backscatter_reflect.m.

d = 2 * bits(:).' - 1;                         % +/-1 BPSK symbol per bit
% For a {0,1} square wave, b(t)=0.5+(2/pi)cos(...). Multiplying by the
% ambient sine carrier gives sidebands at fc +/- fo with coefficient 1/pi.
% The absolute scale is not important for the BER sweep, but keeping this
% coefficient consistent with Eq. 7-8 makes the baseband-equivalent model
% match the literal passband model.
harmonic_weight = 1 / pi;                      % m=1 reflected sideband weight
env = harmonic_weight * repelem(d, p.Nb);      % NRZ at Nb samples/bit
env = complex(env);
end
