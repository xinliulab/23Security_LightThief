function [bits, synced] = recover(baseband, p)
%RECOVER  Recover the bit-rate BPSK symbols from the down-converted harmonic.
%   Pipeline (paper Sec. 5.3): DC-offset removal -> integrate-and-dump matched
%   filter -> coarse CFO removal -> per-bit timing recovery -> static phase
%   de-rotation -> Costas carrier tracking -> hard BPSK slice.  Operates at Nb
%   samples per bit and returns one recovered bit per OWC bit period
%   (Manchester is already demodulated by the harmonic selection).

baseband = baseband - mean(baseband);
mf = matched_filter(baseband, p.Nb);
corrected = coarse_cfo(mf, p.fs_bb);
symbols = symbol_sync(corrected, p.Nb);     % one complex sample per bit
symbols = derotate_phase(symbols);
synced = costas_bpsk(symbols);
bits = double(real(synced) > 0);
end
