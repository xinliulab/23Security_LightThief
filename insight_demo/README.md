# Sine-wave reflection insight

`run_sine_reflection_demo.m` illustrates the simplified switching-backscatter
relationship

```text
reflected(t) = incident_sine(t) × tag_switch(t)
```

Multiplication by a zero-mean square wave translates the incident carrier to
odd-harmonic sidebands around the carrier. The script plots the incident signal,
the switching coefficient, and the reflected spectrum.
