function [pb, fs_rf, fc_sim, f_sw] = to_passband(chips, sps, chip_rate, osr, sw_mult, fc_ratio)
%TO_PASSBAND  Real passband signal on a downscaled carrier (harmonic comb visible).
%   fs_rf = chip_rate*sps*osr.  The chip-domain BPSK data is interpolated up to
%   RF rate, multiplied by a +/-1 square subcarrier at f_sw = sw_mult*chip_rate,
%   then by a cosine carrier at fc_sim.  The zero-mean square wave gives a
%   suppressed-carrier comb at fc_sim +/- k*f_sw, k = 1,3,5,...
%   The subcarrier must sit well above the data bandwidth (~chip_rate) so the
%   harmonics do not overlap, hence sw_mult >= 3.  Requires Signal Proc Toolbox
%   (resample) for clean upsampling so images do not land on the harmonics.

if nargin < 2, sps = 4; end
if nargin < 3, chip_rate = 100e3; end
if nargin < 4, osr = 16; end
if nargin < 5, sw_mult = 4; end
if nargin < 6, fc_ratio = 0.3; end

data = bpsk_pulse_shape(chips, sps);
fs_chip = chip_rate * sps;
fs_rf = fs_chip * osr;
fc_sim = fc_ratio * fs_rf;             % < fs_rf/2, safely below Nyquist
f_sw = sw_mult * chip_rate;            % subcarrier fundamental (Hz)

data_rf = resample(data(:), osr, 1).'; % clean polyphase upsample, keep row
t = (0:numel(data_rf) - 1) / fs_rf;
sq = sign(sin(2 * pi * f_sw * t));
carrier = cos(2 * pi * fc_sim * t);
pb = data_rf .* sq .* carrier;
end
