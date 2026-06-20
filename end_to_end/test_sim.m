function test_sim()
%TEST_SIM  Round-trip and component unit checks for the LightThief simulation.
%   Run:  test_sim

chip_rate = 100e3;
sps = 4;

% --- coding round-trip (no DSP) ------------------------------------------------
[chips, truth] = build_frame('LightThief}{0', 2);
res = decode_chips(chips, [], numel(truth));
check('coding round-trip (no DSP) recovers text', strcmp(res.text, 'LightThief}{0'));
check('coding round-trip BER == 0', ber_calc(res.bytes, truth) == 0);

% --- Hamming single-bit correction over all 256 bytes + 12 positions ----------
n_ok = 0;
for byte = 0:255
    chips_b = encode_byte(byte);
    mpdu = manchester_decode(chips_b);
    codeword = mpdu(2:end);
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

% --- baseband chain @12 dB -----------------------------------------------------
[chips, truth] = build_frame('LightThief', 8);
bb = to_baseband_harmonic(chips, sps);
cfg = lt_default_channel(chip_rate * sps, 12, 1);
cfg.freq_offset = 7e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 15;
rec = recover(channel_apply(bb, cfg), chip_rate, sps);
res = decode_chips(rec, [], numel(truth));
check('baseband chain @12 dB decodes ''LightThief''', strcmp(res.text, 'LightThief'));
check('baseband chain BER == 0', ber_calc(res.bytes, truth) == 0);

% --- passband (harmonic-extracted) chain @15 dB --------------------------------
[chips, truth] = build_frame('LightThief', 6);
[pb, fs_rf, fc_sim, f_sw] = to_passband(chips, sps, chip_rate);
bb = band_select(pb, fs_rf, fc_sim, f_sw, chip_rate, sps, 1);
cfg = lt_default_channel(chip_rate * sps, 15, 2);
cfg.freq_offset = 5e3; cfg.phase_offset_deg = 10; cfg.timing_ppm = 10;
rec = recover(channel_apply(bb, cfg), chip_rate, sps);
res = decode_chips(rec, [], numel(truth));
check('passband (harmonic-extracted) chain @15 dB decodes text', strcmp(res.text, 'LightThief'));

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
