function make_figures()
%MAKE_FIGURES  Generate the stage-by-stage pipeline figures for walkthrough.html.
%   One PNG per signal-processing stage of the paper-faithful LightThief model,
%   written to figures/.  Run:  make_figures
%
%   Stages (paper section in parentheses):
%     01 coded bitstream            (Sec. 6)
%     02 Manchester chips           (Sec. 3.2, Fig. 4)
%     03 optical OOK light waveform (Sec. 3.2)
%     04 tag switching control      (Sec. 4.1, Fig. 5)
%     05 reflected RF waveform      (Sec. 4.4, Eq. 8)
%     06 reflected spectrum / comb  (Sec. 4.4, Fig. 10)
%     07 received noisy baseband    (Sec. 5.3)
%     08 synchronized constellation (Sec. 5.3)
%     09 decoded message            (Sec. 5.3, 6)
%     10 BER curve                  (Sec. 7.2, Fig. 16a)

p = lt_params();
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end
blue = [0.09 0.42 0.53]; orange = [0.84 0.42 0.18]; green = [0.17 0.48 0.33];

% A short packet window for readable waveform plots.
demo_bits = build_packet_stream('Hi', p.preamble); % 10 preamble + 2*13 = 36 bits
nb_show = 24;                                       % bits to display in waveforms
bshow = demo_bits(1:nb_show);

%% 01 - coded bitstream --------------------------------------------------------
f = newfig(900, 240);
stairs([bshow bshow(end)], 'LineWidth', 1.6, 'Color', blue); ylim([-0.3 1.3]);
xlim([1 nb_show + 1]); yticks([0 1]); grid on;
xline(numel(p.preamble) + 1, 'r--', 'LineWidth', 1.2);
text(numel(p.preamble) / 2 + 1, 1.18, 'preamble', 'HorizontalAlignment', 'center', 'Color', orange, 'FontWeight', 'bold');
text((numel(p.preamble) + nb_show) / 2 + 1, 1.18, 'Hamming(12,8)+parity codeword', 'HorizontalAlignment', 'center', 'Color', green, 'FontWeight', 'bold');
title('Stage 1 - Coded bitstream: 10-bit preamble + 13-bit codewords (paper Sec. 6)');
xlabel('bit index'); ylabel('bit'); savef(f, fig_dir, '01_bitstream');

%% 02 - Manchester chips -------------------------------------------------------
chips = manchester_enc(bshow);
f = newfig(900, 240);
stairs([chips chips(end)], 'LineWidth', 1.6, 'Color', orange); ylim([-0.3 1.3]);
xlim([1 numel(chips) + 1]); yticks([0 1]); grid on;
for b = 1:nb_show, xline(2 * b - 1, ':', 'Color', [.7 .7 .7]); end
title('Stage 2 - Manchester line code: each bit -> 2 balanced chips, 1->[1 0], 0->[0 1] (Fig. 4)');
xlabel('chip index'); ylabel('chip'); savef(f, fig_dir, '02_manchester_chips');

%% 03 - optical OOK light waveform --------------------------------------------
spc = 40;                                          % samples/chip for a smooth square wave
[~, light] = optical_waveform(bshow, spc);
tt = (0:numel(light) - 1) / (p.chip_rate * spc) * 1e6;   % microseconds
f = newfig(900, 240);
area(tt, light, 'FaceColor', [1 0.93 0.75], 'EdgeColor', orange, 'LineWidth', 1.4); ylim([-0.2 1.2]);
xlim([0 tt(end)]); yticks([0 1]); yticklabels({'dark','bright'}); grid on;
title('Stage 3 - Optical signal: Manchester OOK light intensity, a square wave at f_o (Sec. 3.2)');
xlabel('time (\mus)'); ylabel('light'); savef(f, fig_dir, '03_optical_waveform');

%% 04 - tag switching control --------------------------------------------------
f = newfig(900, 240);
stairs(tt, light, 'LineWidth', 1.8, 'Color', blue); ylim([-0.2 1.2]);
xlim([0 tt(end)]); yticks([0 1]); yticklabels({'match (no reflect)','short (reflect)'}); grid on;
title('Stage 4 - Tag switching: the light On/Off sets the PD impedance / reflection state (Fig. 5)');
xlabel('time (\mus)'); ylabel('\Gamma state'); savef(f, fig_dir, '04_tag_switching');

%% 05 - reflected RF waveform --------------------------------------------------
[r, trf, light_rf] = backscatter_reflect(bshow, p);
nshow = round(6 * p.fs_rf / p.chip_rate);          % ~6 chips
idx = 1:min(nshow, numel(r));
f = newfig(900, 260);
plot(trf(idx) * 1e6, r(idx), 'Color', blue, 'LineWidth', 0.7); hold on;
plot(trf(idx) * 1e6, light_rf(idx), 'r--', 'LineWidth', 1.4);
xlim([0 trf(idx(end)) * 1e6]); ylim([-1.2 1.2]); grid on;
legend({'reflected RF  r(t)=b(t)\cdotsin(2\pi f_c t)', 'light gate b(t)'}, 'Location', 'southeast');
title('Stage 5 - Reflected RF: light gates the ambient carrier (paper Eq. 8)');
xlabel('time (\mus)'); ylabel('amplitude'); savef(f, fig_dir, '05_reflected_waveform');

%% 06 - reflected spectrum / harmonic comb ------------------------------------
packet_ids = {'LT-ROOM-041', 'LT-ROOM-042', 'LT-ROOM-043'};
[frame_bits, truth_packets, packet_ids] = build_packet_stream(packet_ids, p.preamble);
packet_lengths = cellfun(@numel, truth_packets);
truth = [truth_packets{:}];
rs = backscatter_reflect(frame_bits, p);
n = numel(rs); spec = 20 * log10(abs(fft(rs .* hann(n).')) + 1e-9);
spec = spec(1:floor(n / 2) + 1); fr = (0:floor(n / 2)) * (p.fs_rf / n) / 1e6;
f = newfig(900, 500);
tiledlayout(2, 1, 'TileSpacing', 'compact');
nexttile;
plot(fr, spec, 'Color', blue, 'LineWidth', 0.8); hold on;
xline(p.fc / 1e6, 'k-', 'LineWidth', 1.1);
for m = [1 3 5], for s = [-1 1]
    xline((p.fc + s * m * p.fo) / 1e6, 'r--', 'LineWidth', 0.6);
end, end
xlim([(p.fc - 6 * p.fo) / 1e6, (p.fc + 6 * p.fo) / 1e6]); grid on;
title('Stage 6 - Reflected spectrum: carrier at f_c (solid), data on f_c \pm m f_o (dashed) (Fig. 10)');
xlabel('frequency (MHz)'); ylabel('magnitude (dB)');
nexttile;
plot(fr, spec, 'Color', blue, 'LineWidth', 0.8); hold on;
fsel = (p.fc + p.fo) / 1e6;
xline(fsel, 'r-', 'LineWidth', 1.2);
xline((p.fc + p.fo - p.Rb / 2) / 1e6, 'b:', 'LineWidth', 1.0);
xline((p.fc + p.fo + p.Rb / 2) / 1e6, 'b:', 'LineWidth', 1.0);
xlim([(p.fc + p.fo - 1.8 * p.Rb) / 1e6, (p.fc + p.fo + 1.8 * p.Rb) / 1e6]); grid on;
title('Zoom: the receiver down-converts the first upper harmonic f_c+f_o');
xlabel('frequency (MHz)'); ylabel('magnitude (dB)'); savef(f, fig_dir, '06_spectrum');

%% 07-09 - receive, synchronize, decode ---------------------------------------
bb = band_select(rs, p, 1);
cfg = lt_default_channel(p.fs_bb, 12, 7);
cfg.freq_offset = 6e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15; cfg.dc_offset = 0.02;
rx = channel_apply(bb, cfg);
[rec_bits, synced] = recover(rx, p);
res = decode_packet_stream(rec_bits, p, packet_lengths, numel(packet_ids));

% 07 received noisy baseband (real part), a readable window
seg = real(rx(1:min(40 * p.Nb, numel(rx))));
f = newfig(900, 240);
plot((0:numel(seg) - 1) / p.Nb, seg, 'Color', orange, 'LineWidth', 0.7); grid on;
xlim([0 numel(seg) / p.Nb]);
title('Stage 7 - Received baseband after down-conversion to f_c+f_o, with CFO+timing+AWGN (Sec. 5.3)');
xlabel('bit index'); ylabel('Re\{rx\}'); savef(f, fig_dir, '07_received_noisy');

% 08 synchronized constellation
s = synced(floor(numel(synced) / 10) + 1:end);
f = newfig(460, 460);
scatter(real(s), imag(s), 14, 'filled', 'MarkerFaceColor', blue, 'MarkerFaceAlpha', 0.5); hold on;
yline(0, 'k'); xline(0, 'k'); lim = 1.2 * max(abs(s)); xlim([-lim lim]); ylim([-lim lim]);
axis square; title('Stage 8 - After sync: two BPSK clusters (one symbol/bit)');
xlabel('In-phase'); ylabel('Quadrature'); savef(f, fig_dir, '08_sync_constellation');

% 09 decoded message panel
f = newfig(900, 240); axis off;
txt = sprintf(['Packets     :  %s | %s | %s\nDecoded     :  %s | %s | %s\nBER         :  %.4f\n' ...
    'Hamming corrections: %d     parity OK: %d/%d     polarity inverted: %d'], ...
    packet_ids{1}, packet_ids{2}, packet_ids{3}, res.texts{1}, res.texts{2}, ...
    res.texts{3}, ber_calc(res.bytes, truth), res.corrections, sum(res.parity_ok), ...
    numel(res.parity_ok), res.inverted);
text(0.02, 0.5, txt, 'FontName', 'Consolas', 'FontSize', 15, 'Color', green, 'VerticalAlignment', 'middle');
title('Stage 9 - Packet sync + Hamming decode -> recovered IDs (Sec. 5.3, 6)');
savef(f, fig_dir, '09_decoded_message');

%% 10 - BER curve (compact sweep) ---------------------------------------------
eb_no = -2:2:18; snr_db = eb_no - 10 * log10(p.Nb);
ber_ids = cell(1, 20);
for k = 1:numel(ber_ids)
    ber_ids{k} = sprintf('LT-%04d', k);
end
[fb, tr_packets] = build_packet_stream(ber_ids, p.preamble);
tr = [tr_packets{:}];
packet_lengths_ber = cellfun(@numel, tr_packets);
nby = numel(tr);
env = to_baseband_equiv(fb, p);
bers = zeros(size(eb_no));
for ii = 1:numel(eb_no)
    e = zeros(1, 4);
    for tnum = 1:4
        cfg = lt_default_channel(p.fs_bb, snr_db(ii), 200 + tnum);
        cfg.freq_offset = 6e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15; cfg.dc_offset = 0.02;
        rec = recover(channel_apply(env, cfg), p);
        rr = decode_packet_stream(rec, p, packet_lengths_ber, numel(ber_ids));
        e(tnum) = ber_calc(rr.bytes, tr);
    end
    bers(ii) = mean(e);
end
floor_ber = 0.5 / nby / 8;
f = newfig(720, 440);
semilogy(eb_no, max(bers, floor_ber), 'o-', 'LineWidth', 1.4, 'Color', blue); grid on;
title('Stage 10 - End-to-end BER vs E_b/N_0 (Sec. 7.2)');
xlabel('E_b/N_0 (dB)'); ylabel('bit error rate'); savef(f, fig_dir, '10_ber_curve');

fprintf('Decoded %d ID packets (BER %.4f). Figures written to %s\n', ...
    res.n_packets, ber_calc(res.bytes, truth), fig_dir);
end


function f = newfig(w, h)
f = figure('Visible', 'off', 'Position', [80 80 w h], 'Color', 'w');
end

function savef(f, fig_dir, name)
set(gca, 'FontSize', 10);
saveas(f, fullfile(fig_dir, [name '.png']));
close(f);
end
