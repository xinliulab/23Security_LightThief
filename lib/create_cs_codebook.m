function create_cs_codebook(cb_size, PA, fname) 
    load("./codebooks/cs_master.mat");
    assert(cb_size<=length(beam_weight), "create_cs_codebook sanity1");
    master = beam_weight;
    beam_weight = cell(1,cb_size);
    for ii=1:cb_size
%         beam_weight{ii} = master{ii};

        entry = master{ii};
        psh = str2num(entry{2});
        psh2 = sv2psh(exp(-1j*2*pi/4.*psh).*exp(1j*PA.PHASE_CAL));
        entry2 = {entry{1}, int2str(psh2), int2str(6*ones(8,1))};
        beam_weight{ii} = entry2;
    end
    if nargin<3
        save("./codebooks/cs.mat","beam_weight");
    else
        save(fname,"beam_weight");
    end
end