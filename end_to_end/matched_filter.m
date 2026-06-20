function out = matched_filter(sig, sps)
%MATCHED_FILTER  Half-sine matched filter (mirrors bpskRx.m).

if nargin < 2, sps = 4; end
pulse = half_sine_pulse(sps);
pulse = pulse / sqrt(sum(pulse .^ 2));
out = conv(sig, fliplr(pulse), 'same');
end
