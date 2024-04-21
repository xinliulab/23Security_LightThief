function sv2codebook(cb_name, sv)
    cb_size = size(sv,2);
    beam_weight = cell(1,cb_size);
    for ii=1:cb_size
        mag = 7*ones(32,1);
        psh = sv2psh(sv(:,ii));
        beam_weight{ii} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
    end
    save(cb_name,"beam_weight");
end