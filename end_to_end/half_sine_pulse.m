function pulse = half_sine_pulse(sps)
%HALF_SINE_PULSE  Half-period sine pulse, sin(0:pi/sps:(sps-1)*pi/sps).
%   The pulse shape used by bpskWaveformGenerator.m.

if nargin < 1, sps = 4; end
pulse = sin((0:sps-1) * pi / sps);
end
