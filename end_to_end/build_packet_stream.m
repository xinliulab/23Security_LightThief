function [stream_bits, truth_packets, ids] = build_packet_stream(ids, preamble)
%BUILD_PACKET_STREAM  Build independent LightThief ID packets.
%   Each packet is self-contained:
%       10-bit preamble + Hamming/parity-coded ASCII ID bits
%   This models the OWC device repeatedly emitting independent IDs, instead of
%   one long frame made by repeating the same payload without packet boundaries.

if nargin < 2 || isempty(preamble), preamble = [1 1 1 1 0 0 0 0 1 0]; end
ids = normalize_ids(ids);

stream_bits = [];
truth_packets = cell(1, numel(ids));
for k = 1:numel(ids)
    msg = char(ids{k});
    payload = encode_text(msg);
    stream_bits = [stream_bits, preamble, payload]; %#ok<AGROW>
    truth_packets{k} = double(msg);
end
end


function ids = normalize_ids(ids)
if ischar(ids)
    ids = {ids};
elseif isstring(ids)
    ids = cellstr(ids);
elseif iscell(ids)
    for k = 1:numel(ids)
        ids{k} = char(ids{k});
    end
else
    error('ids must be a char vector, string array, or cell array of IDs');
end
end
