function run_ber()
%RUN_BER  BER-vs-SNR sweep for the LightThief decoder (complex-baseband).
%   Mirrors the Ec/No grid in simulation.m (Ec/No = -25:2.5:17.5, per-sample
%   SNR = EcNo - 10*log10(sps)).  Saves matlab_sim/figures/ber_curve.png.

chip_rate = 100e3;
sps = 4;
ec_no = -25:2.5:17.5;
snr_db = ec_no - 10 * log10(sps);
n_repeat = 40;
n_trials = 6;
message = 'LightThief';
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

[chips, truth] = build_frame(message, n_repeat);
n_bytes = numel(truth) * n_repeat;
bb = to_baseband_harmonic(chips, sps);
fs = chip_rate * sps;

bers = zeros(size(ec_no));
for ii = 1:numel(ec_no)
    errs = zeros(1, n_trials);
    for trial = 1:n_trials
        cfg = lt_default_channel(fs, snr_db(ii), 1000 + trial);
        cfg.freq_offset = 6e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15;
        rec = recover(channel_apply(bb, cfg), chip_rate, sps);
        res = decode_chips(rec, [], n_bytes);
        errs(trial) = ber_calc(res.bytes, truth);
    end
    bers(ii) = mean(errs);
    fprintf('Ec/No %+6.1f dB | SNR %+6.1f dB | BER %.4e\n', ec_no(ii), snr_db(ii), bers(ii));
end

floor_ber = 0.5 / (numel(message) * n_repeat * 8);
f = figure('Visible', 'off', 'Position', [100 100 700 450]);
semilogy(ec_no, max(bers, floor_ber), 'o-', 'LineWidth', 1.2);
grid on;
title('LightThief decoder: BER vs Ec/No (with CFO+phase+timing+AWGN)');
xlabel('Ec/No (dB)'); ylabel('Bit error rate');
saveas(f, fullfile(fig_dir, 'ber_curve.png'));
close(f);
fprintf('\nFigure written to %s\n', fullfile(fig_dir, 'ber_curve.png'));
end
