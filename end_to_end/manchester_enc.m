function chips = manchester_enc(bits)
%MANCHESTER_ENC  IEEE 802.3 Manchester encode: 1 -> [1 0], 0 -> [0 1].

bits = bits(:).';
chips = zeros(1, 2 * numel(bits));
chips(1:2:end) = bits;
chips(2:2:end) = 1 - bits;
end
