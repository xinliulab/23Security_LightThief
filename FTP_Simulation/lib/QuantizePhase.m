function [res] = QuantizePhase(sv, nqbit)
    div = (2*pi)/2^nqbit;
    res = exp(1j*round(angle(sv)/div)*div);
end