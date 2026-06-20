# LightThief — end-to-end MATLAB simulation

A paper-faithful simulation of the LightThief attack (Liu et al., *"LightThief:
Your Optical Communication Information is Stolen behind the Wall,"* USENIX
Security 2023). It follows the paper's signal model exactly: the room's
**data-coded light** (Manchester-OOK) switches a passive tag that backscatters
an ambient RF carrier, placing the OWC data on harmonics at `fc ± m·fo`
(Eq. 7–8); the attacker selects the first harmonic and decodes it (Sec. 5.3).

For a stage-by-stage, paper-aligned reading map of the code (with figures), open
[`walkthrough.html`](walkthrough.html) in a browser.

## Run

```matlab
test_sim                 % component + end-to-end checks
run_demo('LightThief')   % one full run: reflect -> wall -> decode (prints text, BER)
make_figures             % regenerate every figures/0*.png used by walkthrough.html
run_ber                  % full BER vs Eb/N0 sweep
```

Requires the Signal Processing Toolbox (`resample`, `decimate`, `hann`).

## Signal model (paper sections)

| Stage | Signal | Paper | Files |
| --- | --- | --- | --- |
| Coding | ASCII → Hamming(12,8)+parity (13-bit), 10-bit preamble | Sec. 6 | `encode_byte.m`, `build_frame.m`, `hamming_12_8.m` |
| Optical signal | Manchester-OOK light = square wave at `fo` | Sec. 3.2, Fig. 4 | `manchester_enc.m`, `optical_waveform.m` |
| Tag switching | light On/Off sets the reflection state (same waveform) | Sec. 4.1, Fig. 5 | `backscatter_reflect.m` |
| Reflection | `r(t) = b(t)·sin(2π·fc·t)` → harmonics `fc ± m·fo` | Sec. 4.4, Eq. 7–8 | `backscatter_reflect.m` |
| Propagation | 3-D Friis link budget; optical 1/(4πd²) | Eq. 1, 4 | `propagation.m` |
| Reception | down-convert `fc+fo`, DC/LPF + impairments | Sec. 5.3 | `band_select.m`, `channel_apply.m` |
| Sync | integrate-and-dump MF, CFO, timing, Costas | Sec. 5.3 | `recover.m`, `matched_filter.m`, `coarse_cfo.m`, `symbol_sync.m`, `costas_bpsk.m` |
| Decode | preamble sync + 0/π resolution, Hamming + parity | Sec. 5.3, 6 | `decode_bits.m`, `find_frame_start.m`, `hamming_decode.m` |
| Evaluation | BER vs Eb/N0 | Sec. 7.2, Fig. 16 | `run_ber.m`, `ber_calc.m` |

## Key parameters (`lt_params.m`)

`Rb = fo = 100 kHz` (optical clock / bit rate), Manchester chip rate `2·Rb`,
RF carrier `fc = 2 MHz` (downscaled from the real 108 MHz only to bound the
sample count — the harmonic structure and decoding are identical), passband
`fs_rf = 20 MHz`, baseband `Nb = 20` samples/bit.

### Modeling note
There is **no separate sub-carrier**: the harmonics come from the optical
Manchester square wave itself, and `fo` is the optical clock rate, not a free
parameter. The optical signal is data-coded (not an unmodulated carrier), and
the tag's binary switching control is that same light. This repository does not
include USRP code or claim hardware validation.
