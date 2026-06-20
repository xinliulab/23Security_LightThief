function wave = bpsk_pulse_shape(chips, sps)
%BPSK_PULSE_SHAPE  Map chips {0,1} -> {-1,+1} and pulse-shape with half-sine.
%   Each symbol becomes one scaled half-sine pulse; pulses are concatenated.

if nargin < 2, sps = 4; end
symbols = 2 * chips(:) - 1;             % column, {-1,+1}
pulse = half_sine_pulse(sps);          % row
M = symbols * pulse;                   % (Nsym x sps), each row = scaled pulse
wave = reshape(M.', 1, []);            % row-major flatten -> symbol pulses in order
end
