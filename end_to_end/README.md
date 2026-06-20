# MATLAB end-to-end simulation

This is the primary LightThief MATLAB simulation implementation.

## Run

```matlab
test_sim
run_demo
run_demo('Hello LightThief')
run_ber
```

## Pipeline

- Hamming(12,8), overall parity, start bit, and Manchester coding
- Half-sine BPSK pulse shaping
- Switching-reflection harmonic model
- CFO, phase offset, timing drift, DC offset, and AWGN
- Harmonic selection, matched filtering, carrier/timing synchronization
- Preamble polarity resolution, Manchester decode, and Hamming correction

The implementation is modular and may be used as a reference when readers
connect their own sample-acquisition front end. This repository does not include
USRP code or claim hardware validation.
