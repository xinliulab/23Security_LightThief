# LightThief end-to-end MATLAB simulation

This folder contains the MATLAB end-to-end simulation for the LightThief signal
chain: data-coded Manchester-OOK light switches the tag reflection, the reflected
RF carries the data on square-wave harmonics, and the receiver selects a harmonic
to synchronize and decode the bytes.

For a stage-by-stage reading map of the code with figures, open
[`walkthrough.html`](walkthrough.html) in a browser.

## Run

```matlab
test_sim                 % component + end-to-end checks
run_demo('LightThief')   % one full run: reflect -> wall -> decode
make_figures             % regenerate the figures used by walkthrough.html
run_ber                  % BER vs Eb/N0 sweep
```

Requires the Signal Processing Toolbox (`resample`, `decimate`, `hann`).

## Signal model

| Stage | Signal | Files |
| --- | --- | --- |
| Coding | ASCII -> Hamming(12,8)+parity, 10-bit preamble | `encode_byte.m`, `build_frame.m`, `hamming_12_8.m` |
| Optical signal | Manchester-OOK light = square wave at `fo` | `manchester_enc.m`, `optical_waveform.m` |
| Tag switching | light On/Off sets the reflection state | `backscatter_reflect.m` |
| Reflection | `r(t) = b(t)*sin(2*pi*fc*t)` -> harmonics `fc +/- m*fo` | `backscatter_reflect.m` |
| Reception | down-convert `fc+fo`, DC/LPF + impairments | `band_select.m`, `channel_apply.m` |
| Sync | matched filter, CFO, timing, Costas | `recover.m`, `matched_filter.m`, `coarse_cfo.m`, `symbol_sync.m`, `costas_bpsk.m` |
| Decode | preamble sync, Hamming + parity | `decode_bits.m`, `find_frame_start.m`, `hamming_decode.m` |

## Key parameters (`lt_params.m`)

`Rb = fo = 100 kHz`, Manchester chip rate `2*Rb`, RF carrier `fc = 2 MHz`,
passband `fs_rf = 20 MHz`, baseband `Nb = 20` samples/bit.

## Modeling note

There is no separate sub-carrier: the harmonics come from the optical Manchester
square wave itself. The optical signal is data-coded, and the tag's binary
switching control is that same light.
