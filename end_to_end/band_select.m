function bb = band_select(passband, p, harmonic)
%BAND_SELECT  Quadrature down-conversion to a reflected harmonic (paper Sec. 5.3).
%   Mixes the chosen reflected harmonic  fc + harmonic*fo  to baseband and
%   decimates to the baseband rate fs_bb = Nb*Rb.  Default harmonic = 1 (the
%   first harmonic fc+fo), exactly as the paper's demodulator.  The strong
%   carrier leakage (at offset -fo after mixing) and the other harmonics are
%   later nulled by the per-bit integrate-and-dump matched filter.
%   Requires Signal Processing Toolbox (decimate).

if nargin < 3 || isempty(harmonic), harmonic = p.harmonic; end

passband = passband(:).';
t = (0:numel(passband) - 1) / p.fs_rf;
f_target = p.fc + harmonic * p.fo;
mixed = 2 * passband .* exp(-1j * 2 * pi * f_target * t);

q = round(p.fs_rf / p.fs_bb);
% decimate() handles real signals only -> process I and Q separately.
bb = decimate(real(mixed), q, 'fir') + 1j * decimate(imag(mixed), q, 'fir');
bb = bb(:).';
end
