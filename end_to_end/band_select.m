function bb = band_select(passband, p, harmonic)
%BAND_SELECT  Quadrature down-conversion to a reflected harmonic (paper Sec. 5.3).
%   The input is the SDR/IQ envelope centered at fc, so the chosen RF harmonic
%   fc + harmonic*fo appears at baseband offset harmonic*fo.  Mixing that offset
%   to zero is equivalent to tuning the receiver to fc+fo as in the paper.
%   The FIR anti-alias / low-pass filter in decimate() then reduces the stream
%   to fs_bb = Nb*Rb.  The strong carrier leakage (at offset -fo after mixing)
%   and the other harmonics are later nulled by the per-bit integrate-and-dump
%   matched filter.
%   Requires Signal Processing Toolbox (decimate).

if nargin < 3 || isempty(harmonic), harmonic = p.harmonic; end

passband = passband(:).';
t = (0:numel(passband) - 1) / p.fs_rf;
f_target = harmonic * p.fo;
mixed = 2 * passband .* exp(-1j * 2 * pi * f_target * t);

q = round(p.fs_rf / p.fs_bb);
if q > 1
    % decimate() handles real signals only -> process I and Q separately.
    bb = decimate(real(mixed), q, 'fir') + 1j * decimate(imag(mixed), q, 'fir');
else
    bb = mixed;
end
bb = bb(:).';
bb = bb - mean(bb);                  % explicit receiver DC-offset removal
end
