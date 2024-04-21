function create_default_codebook(cb_size, PA)
    load("./codebooks/default_master.mat");
    assert(cb_size<=length(beam_weight), "create_default_codebook sanity1");
    master = beam_weight;
    beam_weight = cell(1,cb_size);
    for ii=1:cb_size
        mag = zeros(32,1); 
        mag(PA.ACTIVE_ANT) = 7*ones(length(PA.ACTIVE_ANT),1);
        master{ii}{1} = int2str(mag);
        
        beam_weight{ii} = master{ii};
    end
    save("./codebooks/default.mat","beam_weight");
end

% %% extract default codebook from sparrow+
% load("./codebooks/default_sparrow+.mat");
% cb_size = 128; 
% beam_weight = cell(1,cb_size);
% % disabled_ant = setdiff([1:32], PA.ACTIVE_ANT);
% for ii=1:cb_size
%     mag = cb{ii}.mag.';
% %     mag = (mag>0)*7;
% %     mag(disabled_ant) = zeros(length(disabled_ant),1);
%     psh = cb{ii}.phase.'; 
%     amp = cb{ii}.amp.';
%     beam_weight{ii} = {int2str(mag), int2str(psh), int2str(amp)};
% end
% save("./codebooks/default_master.mat","beam_weight");