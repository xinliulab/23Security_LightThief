function bb = band_select(passband, fs_rf, fc_sim, f_sw, chip_rate, sps, harmonic)
%BAND_SELECT  Mix the chosen harmonic (fc_sim + harmonic*f_sw) to DC and decimate.
%   Returns the complex baseband of that harmonic at rate chip_rate*sps.
%   Requires Signal Processing Toolbox (decimate).

if nargin < 6 || isempty(sps), sps = 4; end
if nargin < 7 || isempty(harmonic), harmonic = 1; end

passband = passband(:).';
t = (0:numel(passband) - 1) / fs_rf;
f_target = fc_sim + harmonic * f_sw;
mixed = passband .* exp(-1j * 2 * pi * f_target * t);

q = round(fs_rf / (chip_rate * sps));
% decimate() handles real signals only -> process I and Q separately.
bb = decimate(real(mixed), q, 'fir') + 1j * decimate(imag(mixed), q, 'fir');
bb = bb(:).';
end
