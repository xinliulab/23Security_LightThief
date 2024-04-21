function create_csi_codebook(cb_size, ref_ant, meas_ant, PA)
    % measurement codebook
    % 4 probes for each antenna except for the reference
    % antenna #1 is assumed to be the reference
%     ref_ant = 1;
%     meas_ant = setdiff(PA.ACTIVE_ANT,[ref_ant]);
    assert(cb_size/4==length(meas_ant), "create_csi_codebook sanity1");
%     meas_ant = meas_ant(1:cb_size/4);
%     cb_size = length(meas_ant)*4; 
    beam_weight = cell(1,cb_size);
    cb_idx = 1;
    for ii=1:length(meas_ant)
        for jj=1:4
            % etype registers (bit2,bit1,bit0) control which antenna is on/off
            mag = 0*ones(32,1);     % turn off all antennas 
            mag(ref_ant) = 7;      % activate ref antenna 
            mag(meas_ant(ii)) = 7; % activate measuring antenna 
            
            psh = zeros(32,1);
            psh(meas_ant(ii)) = mod(-(jj-1), 4); %floor(mod((cb_idx-1)/4,4));
            beam_weight{cb_idx} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
            cb_idx = cb_idx + 1;
        end
    end
    save("./codebooks/csi.mat","beam_weight");
end