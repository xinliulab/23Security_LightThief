function [r, t, light, chips] = backscatter_reflect(bits, p)
%BACKSCATTER_REFLECT  Reflected RF from the LightThief tag (paper Eq. 7-8).
%
%   The tag's PD impedance is switched by the incident light's On/Off intensity,
%   so the antenna reflects an amount of the ambient continuous wave (CW) that
%   follows the optical square wave.  Modeling the two reflection states as a
%   gate b(t) in {0,1} on the CW:
%
%       S_cw  = sin(2*pi*fc*t)                          (ambient CW)
%       b(t)  = Manchester OOK light intensity in {0,1} (paper S_sqw, Eq. 7,
%               whose 0.5 DC term is the un-shifted carrier leakage)
%       r(t)  = b(t) .* S_cw                            (reflected RF, Eq. 8)
%
%   The {0,1} gate is important: its 0.5 DC term leaves carrier leakage at fc,
%   while each odd harmonic carries an equivalent +/-1 BPSK phase term.  After
%   the receiver selects fc+fo, the recovered data is therefore sliced as BPSK.
%
%   Because b(t) is a square wave at the optical clock rate f_o, its odd Fourier
%   harmonics place copies of the data at  fc +/- m*f_o  (m = 1,3,5,...) with the
%   bit embedded in the harmonic phase theta_n.  The harmonics are intrinsic to
%   the optical square wave -- there is NO separate sub-carrier.
%
%   Returns the reflected RF complex envelope centered at fc, its time base t,
%   the light intensity waveform, and the Manchester chips.  This mirrors the
%   SDR/USRP view: fc is the RF tuning center, and this MATLAB waveform contains
%   the offsets 0, +/-fo, +/-3fo, ... around that center.

samples_per_chip = round(p.fs_rf / p.chip_rate);     % RF samples per Manchester chip
[chips, light] = optical_waveform(bits, samples_per_chip);

t = (0:numel(light) - 1) / p.fs_rf;
r = complex(light);                                   % RF envelope after tuning to fc
end
