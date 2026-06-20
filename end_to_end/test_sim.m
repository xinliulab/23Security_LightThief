function test_sim()
%TEST_SIM  Round-trip and component unit checks for the LightThief simulation.
%   Run:  test_sim

p = lt_params();

% --- coding round-trip (no DSP): bits -> decode_bits -------------------------
[frame_bits, truth] = build_frame('LightThief}{0', 1);
res = decode_bits(frame_bits, p, numel(truth));
check('coding round-trip (no DSP) recovers text', strcmp(res.text, 'LightThief}{0'));
check('coding round-trip BER == 0', ber_calc(res.bytes, truth) == 0);

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

% --- baseband-equivalent chain @10 dB (CFO+phase+timing+AWGN) ----------------
[frame_bits, truth] = build_frame('LightThief', 8);
env = to_baseband_equiv(frame_bits, p);
cfg = lt_default_channel(p.fs_bb, 10, 1);
cfg.freq_offset = 7e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15;
rec = recover(channel_apply(env, cfg), p);
res = decode_bits(rec, p, numel(truth));
check('baseband-equivalent chain @10 dB decodes ''LightThief''', strcmp(res.text, 'LightThief'));
check('baseband-equivalent chain BER == 0', ber_calc(res.bytes, truth) == 0);

% --- full physical passband chain: reflect -> band-select -> decode ----------
[frame_bits, truth] = build_frame('LightThief', 6);
r = backscatter_reflect(frame_bits, p);
bb = band_select(r, p, 1);
cfg = lt_default_channel(p.fs_bb, 15, 2);
cfg.freq_offset = 5e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 10;
rec = recover(channel_apply(bb, cfg), p);
res = decode_bits(rec, p, numel(truth));
check('physical passband (harmonic-extracted) chain @15 dB decodes text', ...
      strcmp(res.text, 'LightThief'));

% --- harmonic comb appears at fc and fc +/- m*fo ----------------------------
r = backscatter_reflect(build_frame('A', 40), p);
B = abs(fft(r .* hann(numel(r)).'));
fr = (0:numel(r) - 1) * (p.fs_rf / numel(r));
peak_near = @(f) any(abs(fr(B > 0.1 * max(B)) - f) < 0.15 * p.fo);
check('comb has carrier at fc', peak_near(p.fc));
check('comb has first harmonic at fc+fo', peak_near(p.fc + p.fo));

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
