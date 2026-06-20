function b = ber_calc(decoded_bytes, truth_bytes)
%BER_CALC  Bit error rate of decoded bytes vs ground-truth byte sequence.

if isempty(decoded_bytes) && isempty(truth_bytes)
    b = 0.0;
    return;
end
if isempty(decoded_bytes) || isempty(truth_bytes)
    b = 1.0;
    return;
end

n_cmp = min(numel(decoded_bytes), numel(truth_bytes));
decoded = decoded_bytes(1:n_cmp);
truth = truth_bytes(1:n_cmp);

x = uint8(bitxor(uint8(decoded), uint8(truth)));
tot = 0;
for bit = 1:8
    tot = tot + sum(double(bitget(x, bit)));
end
tot = tot + 8 * abs(numel(decoded_bytes) - numel(truth_bytes));
b = tot / (max(numel(decoded_bytes), numel(truth_bytes)) * 8);
end
