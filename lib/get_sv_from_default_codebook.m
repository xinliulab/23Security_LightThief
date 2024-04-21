function [sv] = get_sv_from_default_codebook(idx)
    load("./codebooks/default.mat");
    sv = zeros(32, length(idx));
    for ii=1:length(idx)
        psh = str2num(beam_weight{idx(ii)}{2});
        sv(:,ii) = exp(-1j*2*pi/4*psh);
    end
end