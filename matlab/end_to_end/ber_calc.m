function b = ber_calc(decoded_bytes, truth_bytes)
%BER_CALC  Bit error rate of decoded bytes vs ground truth (tiled to match).

if isempty(decoded_bytes)
    b = 1.0;
    return;
end
idx = mod(0:numel(decoded_bytes) - 1, numel(truth_bytes)) + 1;
truth = truth_bytes(idx);

x = uint8(bitxor(uint8(decoded_bytes), uint8(truth)));
tot = 0;
for bit = 1:8
    tot = tot + sum(double(bitget(x, bit)));
end
b = tot / (numel(decoded_bytes) * 8);
end
