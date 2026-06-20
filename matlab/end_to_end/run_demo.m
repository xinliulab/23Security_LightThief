function run_demo(message)
%RUN_DEMO  End-to-end LightThief demo: light TX -> backscatter -> wall -> decode.
%   Runs the full physical path (real downscaled carrier, square-wave reflection,
%   harmonic comb, band-select, impairments, decode), prints the recovered text,
%   and saves two figures under matlab_sim/figures.
%
%   Usage:  run_demo            % default message
%           run_demo('Hello')

if nargin < 1, message = 'LightThief'; end
chip_rate = 100e3;
sps = 4;
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

% --- TX: encode + backscatter onto a (downscaled) RF carrier ------------------
[chips, truth] = build_frame(message, 8);
[pb, fs_rf, fc_sim, f_sw] = to_passband(chips, sps, chip_rate);
fprintf('Backscatter: fs_rf=%.2f MHz, carrier fc=%.2f MHz, subcarrier f_sw=%.0f kHz\n', ...
    fs_rf / 1e6, fc_sim / 1e6, f_sw / 1e3);
fprintf('Harmonic comb at fc +/- k*f_sw (k=1: %.2f/%.2f MHz, k=3: %.2f/%.2f MHz)\n', ...
    (fc_sim - f_sw) / 1e6, (fc_sim + f_sw) / 1e6, ...
    (fc_sim - 3 * f_sw) / 1e6, (fc_sim + 3 * f_sw) / 1e6);

% --- Attacker RX: pick +1 harmonic, through-wall impairments ------------------
bb = band_select(pb, fs_rf, fc_sim, f_sw, chip_rate, sps, 1);
cfg = lt_default_channel(chip_rate * sps, 15, 7);
cfg.freq_offset = 6e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15;
rx = channel_apply(bb, cfg);

[rec_chips, synced] = recover(rx, chip_rate, sps);
res = decode_chips(rec_chips, [], numel(truth));

fprintf('\nTransmitted : %s\n', message);
fprintf('Decoded     : %s\n', res.text);
fprintf('BER         : %.4f\n', ber_calc(res.bytes, truth));
fprintf('Hamming corrections: %d, parity OK: %d/%d, stream inverted: %d\n', ...
    res.corrections, sum(res.parity_ok), numel(res.parity_ok), res.inverted);

plot_comb(pb, fs_rf, fc_sim, f_sw, fig_dir);
plot_constellation(synced, fig_dir);
fprintf('\nFigures written to %s\n', fig_dir);
end


function plot_comb(pb, fs_rf, fc_sim, f_sw, fig_dir)
n = numel(pb);
win = hann(n).';
spec = 20 * log10(abs(fft(pb .* win)) + 1e-9);
spec = spec(1:floor(n / 2) + 1);
freqs = (0:floor(n / 2)) * (fs_rf / n) / 1e6;
f = figure('Visible', 'off', 'Position', [100 100 800 400]);
plot(freqs, spec, 'LineWidth', 0.8); hold on;
for k = [1 3 5]
    for s = [-1 1]
        fk = (fc_sim + s * k * f_sw) / 1e6;
        if fk > 0 && fk < fs_rf / 2e6
            xline(fk, 'r--', 'LineWidth', 0.6);
        end
    end
end
xline(fc_sim / 1e6, 'k:', 'LineWidth', 0.8);
title('Backscattered passband: harmonic comb at fc +/- k*f\_sw');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
saveas(f, fullfile(fig_dir, 'harmonic_comb.png'));
close(f);
end


function plot_constellation(synced, fig_dir)
s = synced(floor(numel(synced) / 10) + 1:end);   % drop acquisition transient
f = figure('Visible', 'off', 'Position', [100 100 450 450]);
scatter(real(s), imag(s), 12, 'filled', 'MarkerFaceAlpha', 0.5); hold on;
yline(0, 'k'); xline(0, 'k');
lim = 1.2 * max(abs(s));
xlim([-lim lim]); ylim([-lim lim]);
title('Recovered BPSK constellation');
xlabel('In-phase'); ylabel('Quadrature'); axis square;
saveas(f, fullfile(fig_dir, 'constellation.png'));
close(f);
end
