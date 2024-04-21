function [res] = quantize_phase(phase, nqbit)
    div = (2*pi)/2^nqbit;
    res = round(phase/div)*div;
end