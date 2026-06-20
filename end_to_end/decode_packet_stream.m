function res = decode_packet_stream(rec_bits, p, n_bytes_per_packet, n_packets)
%DECODE_PACKET_STREAM  Decode independent preamble-delimited ID packets.
%   The first preamble establishes frame timing and resolves the BPSK 0/pi
%   ambiguity.  Subsequent packet boundaries are then parsed using the known ID
%   byte lengths, so each packet remains independent on the wire.

if nargin < 2 || isempty(p), p = lt_params(); end
if nargin < 3 || isempty(n_bytes_per_packet), error('n_bytes_per_packet is required'); end
if nargin < 4 || isempty(n_packets), n_packets = numel(n_bytes_per_packet); end
if isscalar(n_bytes_per_packet)
    n_bytes_per_packet = repmat(n_bytes_per_packet, 1, n_packets);
end

[start_after_preamble, invert] = find_frame_start(rec_bits, p.preamble);
if invert
    rec_bits = 1 - rec_bits;
end

packet_start = start_after_preamble - numel(p.preamble);   % 0-based
packets = struct('bytes', {}, 'text', {}, 'corrections', {}, ...
    'parity_ok', {}, 'start', {});

cursor = packet_start;
for k = 1:n_packets
    n_bytes = n_bytes_per_packet(k);
    payload_start = cursor + numel(p.preamble);             % 0-based
    payload_end = payload_start + n_bytes * p.code_len;     % 0-based exclusive
    if payload_end > numel(rec_bits)
        break;
    end

    payload = rec_bits(payload_start + 1:payload_end);
    bytes = [];
    corrections = 0;
    parity_ok = [];
    for w = 0:n_bytes - 1
        codeword = payload(w * p.code_len + 1:(w + 1) * p.code_len);
        [byte, corrected, pok] = hamming_decode(codeword);
        bytes(end + 1) = byte; %#ok<AGROW>
        corrections = corrections + corrected;
        parity_ok(end + 1) = pok; %#ok<AGROW>
    end

    packets(k).bytes = bytes; %#ok<AGROW>
    packets(k).text = char(bytes);
    packets(k).corrections = corrections;
    packets(k).parity_ok = parity_ok;
    packets(k).start = cursor;
    cursor = payload_end;
end

res = struct();
res.packets = packets;
res.texts = {packets.text};
res.bytes = [packets.bytes];
res.corrections = sum([packets.corrections]);
res.parity_ok = [packets.parity_ok];
res.inverted = invert;
res.start = packet_start;
res.n_packets = numel(packets);
end
