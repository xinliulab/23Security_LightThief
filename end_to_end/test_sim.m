function test_sim()
%TEST_SIM  Round-trip and component unit checks for the LightThief simulation.
%   Run:  test_sim

p = lt_params();

% --- coding round-trip (no DSP): bits -> decode_bits -------------------------
[frame_bits, truth] = build_frame('LightThief}{0', 1);
res = decode_bits(frame_bits, p, numel(truth));
check('coding round-trip (no DSP) recovers text', strcmp(res.text, 'LightThief}{0'));
check('coding round-trip BER == 0', ber_calc(res.bytes, truth) == 0);

% --- independent packet stream: each ID has its own preamble ------------------
ids = {'LT-ROOM-041', 'LT-ROOM-042', 'LT-ROOM-043'};
[packet_bits, packet_truth, ids] = build_packet_stream(ids, p.preamble);
packet_lengths = cellfun(@numel, packet_truth);
pres = decode_packet_stream(packet_bits, p, packet_lengths, numel(ids));
check('packet stream round-trip recovers independent IDs', isequal(pres.texts, ids));

% --- Hamming single-bit correction over all 256 bytes + 12 positions --------
n_ok = 0;
for byte = 0:255
    codeword = encode_byte(byte);                 % 13-bit codeword
    for pos = 1:12
        corrupted = codeword;
        corrupted(pos) = 1 - corrupted(pos);
        [dec, corrected, ~] = hamming_decode(corrupted);
        if dec == byte && corrected
            n_ok = n_ok + 1;
        end
    end
end
check('Hamming corrects every single-bit error in all 256 bytes', n_ok == 256 * 12);

% --- baseband-equivalent chain @10 dB (CFO+phase+timing+DC+AWGN) -------------
[frame_bits, truth_packets, ids] = build_packet_stream(ids, p.preamble);
packet_lengths = cellfun(@numel, truth_packets);
truth = [truth_packets{:}];
env = to_baseband_equiv(frame_bits, p);
cfg = lt_default_channel(p.fs_bb, 10, 1);
cfg.freq_offset = 7e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15; cfg.dc_offset = 0.02;
rec = recover(channel_apply(env, cfg), p);
res = decode_packet_stream(rec, p, packet_lengths, numel(ids));
check('baseband-equivalent chain @10 dB decodes independent IDs', isequal(res.texts, ids));
check('baseband-equivalent chain BER == 0', ber_calc(res.bytes, truth) == 0);

% --- full physical passband chain: reflect -> band-select -> decode ----------
[frame_bits, truth_packets, ids] = build_packet_stream({'LT-108A', 'LT-108B'}, p.preamble);
packet_lengths = cellfun(@numel, truth_packets);
truth = [truth_packets{:}];
r = backscatter_reflect(frame_bits, p);
bb = band_select(r, p, 1);
cfg = lt_default_channel(p.fs_bb, 15, 2);
cfg.freq_offset = 5e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 10; cfg.dc_offset = 0.02;
rec = recover(channel_apply(bb, cfg), p);
res = decode_packet_stream(rec, p, packet_lengths, numel(ids));
check('physical passband (harmonic-extracted) chain @15 dB decodes IDs', ...
      isequal(res.texts, ids));

% --- harmonic comb appears at fc and fc +/- m*fo ----------------------------
[comb_bits] = build_packet_stream({'A1', 'B2', 'C3', 'D4'}, p.preamble);
r = backscatter_reflect(comb_bits, p);
B = abs(fftshift(fft(r .* hann(numel(r)).')));
fr = ((0:numel(r) - 1) - floor(numel(r) / 2)) * (p.fs_rf / numel(r));
peak_near = @(f) any(abs(fr(B > 0.1 * max(B)) - f) < 0.15 * p.fo);
check('comb has carrier leakage at fc offset', peak_near(0));
check('comb has first harmonic at fc+fo offset', peak_near(p.fo));

fprintf('\nAll tests passed.\n');
end


function check(name, cond)
if cond
    fprintf('[PASS] %s\n', name);
else
    fprintf('[FAIL] %s\n', name);
    error('Test failed: %s', name);
end
end
