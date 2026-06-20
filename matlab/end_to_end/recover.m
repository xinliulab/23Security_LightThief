function [chips, synced] = recover(baseband, chip_rate, sps)
%RECOVER  Full recovery of a complex-baseband signal -> chip bits + synced symbols.
%   matched filter -> coarse CFO -> phase de-rotation -> timing sync -> Costas.

if nargin < 3, sps = 4; end
fs = chip_rate * sps;

mf = matched_filter(baseband, sps);
corrected = coarse_cfo(mf, fs);
symbols = symbol_sync(corrected, sps);
symbols = derotate_phase(symbols);
synced = costas_bpsk(symbols);
chips = double(real(synced) > 0);
end
