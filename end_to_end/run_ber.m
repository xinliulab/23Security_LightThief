function run_ber()
%RUN_BER  BER-vs-Eb/N0 sweep for the LightThief decoder.
%   Sweeps an Eb/N0 grid on the complex-baseband-equivalent of the selected
%   reflected harmonic, with CFO + phase + timing drift + AWGN, and decodes the
%   full coding chain.  Saves figures/ber_curve.png.

p = lt_params();
eb_no = -4:1.5:20;                         % Eb/N0 grid (dB)
snr_db = eb_no - 10 * log10(p.Nb);         % per-baseband-sample SNR (Nb samples/bit)
n_repeat = 40;
n_trials = 6;
message = 'LightThief';
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

[frame_bits, truth] = build_frame(message, n_repeat);
n_bytes = numel(truth) * n_repeat;
env = to_baseband_equiv(frame_bits, p);

bers = zeros(size(eb_no));
for ii = 1:numel(eb_no)
    errs = zeros(1, n_trials);
    for trial = 1:n_trials
        cfg = lt_default_channel(p.fs_bb, snr_db(ii), 1000 + trial);
        cfg.freq_offset = 6e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15;
        rec = recover(channel_apply(env, cfg), p);
        res = decode_bits(rec, p, n_bytes);
        errs(trial) = ber_calc(res.bytes, truth);
    end
    bers(ii) = mean(errs);
    fprintf('Eb/N0 %+6.1f dB | SNR %+6.1f dB | BER %.4e\n', eb_no(ii), snr_db(ii), bers(ii));
end

floor_ber = 0.5 / (numel(message) * n_repeat * 8);
f = figure('Visible', 'off', 'Position', [100 100 700 450]);
semilogy(eb_no, max(bers, floor_ber), 'o-', 'LineWidth', 1.2);
grid on;
title('LightThief decoder: BER vs E_b/N_0 (with CFO+phase+timing+AWGN)');
xlabel('E_b/N_0 (dB)'); ylabel('Bit error rate');
saveas(f, fullfile(fig_dir, 'ber_curve.png'));
close(f);
fprintf('\nFigure written to %s\n', fullfile(fig_dir, 'ber_curve.png'));
end
