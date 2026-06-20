function run_demo(packet_ids)
%RUN_DEMO  End-to-end LightThief demo (paper-faithful signal model).
%   OWC light (Manchester OOK) -> tag switches reflection of an ambient CW ->
%   reflected RF harmonics at fc +/- m*fo -> attacker selects the m=1 harmonic
%   -> wall/RF impairments -> synchronize -> decode.  Prints the recovered ID
%   packets and saves harmonic_comb.png and constellation.png under figures/.
%
%   Usage:  run_demo                         % default independent ID packets
%           run_demo('LT-ROOM-042')          % one ID packet
%           run_demo({'LT-001','LT-002'})    % several independent packets

if nargin < 1, packet_ids = {'LT-ROOM-041', 'LT-ROOM-042', 'LT-ROOM-043'}; end
p = lt_params();
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

% --- TX + physical reflection -------------------------------------------------
[frame_bits, truth_packets, packet_ids] = build_packet_stream(packet_ids, p.preamble);
packet_lengths = cellfun(@numel, truth_packets);
truth = [truth_packets{:}];
r = backscatter_reflect(frame_bits, p);
fprintf('Optical clock fo=%.0f kHz, RF carrier fc=%.2f MHz, fs_rf=%.1f MHz\n', ...
    p.fo / 1e3, p.fc / 1e6, p.fs_rf / 1e6);
fprintf('Reflected harmonics at fc +/- m*fo (m=1: %.2f/%.2f MHz, m=3: %.2f/%.2f MHz)\n', ...
    (p.fc - p.fo) / 1e6, (p.fc + p.fo) / 1e6, ...
    (p.fc - 3 * p.fo) / 1e6, (p.fc + 3 * p.fo) / 1e6);

% --- 3-D propagation link budget (Eq. 1, 4): geometry -> operating SNR --------
link = propagation(p, struct('d_ph', 0.3, 'd_t', 1.0, 'd_r', 10.0));
fprintf('Link budget: d_ph=%.1fm d_t=%.1fm d_r=%.1fm -> RSS %.1f dBm, SNR %.1f dB\n', ...
    link.d_ph, link.d_t, link.d_r, link.RSS_dBm, link.snr_db);

% --- Attacker RX: select m=1 harmonic, through-wall impairments ---------------
bb = band_select(r, p, 1);
cfg = lt_default_channel(p.fs_bb, 15, 7);
cfg.freq_offset = 6e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15; cfg.dc_offset = 0.02;
rx = channel_apply(bb, cfg);

[rec_bits, synced] = recover(rx, p);
res = decode_packet_stream(rec_bits, p, packet_lengths, numel(packet_ids));

fprintf('\nRecovered independent ID packets:\n');
for k = 1:numel(packet_ids)
    decoded = '';
    if k <= numel(res.texts), decoded = res.texts{k}; end
    fprintf('  %02d TX: %-12s  RX: %s\n', k, packet_ids{k}, decoded);
end
fprintf('BER         : %.4f\n', ber_calc(res.bytes, truth));
fprintf('Hamming corrections: %d, parity OK: %d/%d, stream inverted: %d\n', ...
    res.corrections, sum(res.parity_ok), numel(res.parity_ok), res.inverted);

plot_comb(r, p, fig_dir);
plot_constellation(synced, fig_dir);
fprintf('\nFigures written to %s\n', fig_dir);
end


function plot_comb(r, p, fig_dir)
n = numel(r);
spec = 20 * log10(abs(fft(r .* hann(n).')) + 1e-9);
spec = spec(1:floor(n / 2) + 1);
freqs = (0:floor(n / 2)) * (p.fs_rf / n) / 1e6;
f = figure('Visible', 'off', 'Position', [100 100 860 560]);
tiledlayout(2, 1, 'TileSpacing', 'compact');
nexttile;
plot(freqs, spec, 'LineWidth', 0.8); hold on;
for m = [1 3 5]
    for s = [-1 1]
        fk = (p.fc + s * m * p.fo) / 1e6;
        if fk > 0 && fk < p.fs_rf / 2e6
            xline(fk, 'r--', 'LineWidth', 0.6);
        end
    end
end
xline(p.fc / 1e6, 'k-', 'LineWidth', 1.0);
title('Reflected RF spectrum: carrier at f_c, data on harmonics f_c \pm m f_o');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([(p.fc - 6 * p.fo) / 1e6, (p.fc + 6 * p.fo) / 1e6]);

nexttile;
plot(freqs, spec, 'LineWidth', 0.8); hold on;
fsel = (p.fc + p.fo) / 1e6;
xline(fsel, 'r-', 'LineWidth', 1.2);
xline((p.fc + p.fo - p.Rb / 2) / 1e6, 'b:', 'LineWidth', 1.0);
xline((p.fc + p.fo + p.Rb / 2) / 1e6, 'b:', 'LineWidth', 1.0);
title('Zoom: receiver selects the first upper harmonic f_c+f_o');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([(p.fc + p.fo - 1.8 * p.Rb) / 1e6, (p.fc + p.fo + 1.8 * p.Rb) / 1e6]);
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
title('Recovered BPSK constellation (one symbol per OWC bit)');
xlabel('In-phase'); ylabel('Quadrature'); axis square;
saveas(f, fullfile(fig_dir, 'constellation.png'));
close(f);
end
