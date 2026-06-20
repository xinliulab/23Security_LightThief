function sig = channel_apply(sig, cfg)
%CHANNEL_APPLY  Through-wall RF impairments (port of channel.m).
%   cfg is a struct with fields:
%       sample_rate       complex baseband rate (chip_rate*sps)
%       freq_offset       carrier frequency offset (Hz)
%       phase_offset_deg  static phase offset (deg)
%       timing_ppm        linear sampling-clock drift (ppm)
%       dc_offset         DC offset as a fraction of peak amplitude
%       snr_db            AWGN SNR (Inf for no noise)
%       seed              RNG seed
%   See lt_default_channel.m for a populated default struct.

s = RandStream('mt19937ar', 'Seed', cfg.seed);
sig = complex(sig(:).');

sig = apply_timing_drift(sig, cfg.timing_ppm);

t = (0:numel(sig) - 1) / cfg.sample_rate;
sig = sig .* exp(1j * (2 * pi * cfg.freq_offset * t + deg2rad(cfg.phase_offset_deg)));

if cfg.dc_offset ~= 0
    sig = sig + cfg.dc_offset * max(abs(sig));
end

sig = add_awgn(sig, cfg.snr_db, s);
end


function out = apply_timing_drift(sig, ppm)
if ppm == 0
    out = sig;
    return;
end
n = numel(sig);
idx = 0:n - 1;
drift = (ppm * 1e-6) * idx;             % cumulative fractional-sample offset
src = min(max(idx + drift, 0), n - 1);
out = interp1(idx, real(sig), src, 'linear') + ...
      1j * interp1(idx, imag(sig), src, 'linear');
end


function out = add_awgn(sig, snr_db, s)
if isinf(snr_db)
    out = sig;
    return;
end
p_sig = mean(abs(sig) .^ 2);
p_noise = p_sig / (10 ^ (snr_db / 10));
noise = sqrt(p_noise / 2) * (randn(s, size(sig)) + 1j * randn(s, size(sig)));
out = sig + noise;
end
