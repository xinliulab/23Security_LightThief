function create_exhaustive_codebook(az,el,CAL,PA) 
    pa = get_phased_array(PA.FREQ, PA.ACTIVE_ANT);
    nqbits = 2;
%     CAL=1;
    cb_size = length(az)*length(el); 
%     assert(cb_size<=128);
    beam_weight = cell(1,cb_size);
    cb_idx = 1;
    tmp = zeros(cb_size, length(PA.ACTIVE_ANT));
    for ii=1:length(az)
        for jj=1:length(el)
            ang = [az(ii); el(jj);]; %[az;el]
            sv = steervec(pa.getElementPosition()/PA.LAM,ang); 
            sv = sv./sv(1).*exp(1j*PA.PHASE_CAL(PA.ACTIVE_ANT)*(CAL==1));
            psh = zeros(32,1);
            psh(PA.ACTIVE_ANT) = sv2psh(sv); 
    %         tmp(cb_idx,:) = sv2psh(sv); 
            mag = zeros(32,1);     % turn off all antennas
            mag(PA.ACTIVE_ANT) = 7*ones(length(PA.ACTIVE_ANT),1);
            beam_weight{cb_idx} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
            cb_idx = cb_idx + 1;
        end
    end
    
    if CAL
        save("./codebooks/exhaustive_cal.mat","beam_weight");
    else
        save("./codebooks/exhaustive_uncal.mat","beam_weight");
    end
    % plot_codebook("./codebooks/directional.mat", fc)  
    fprintf("Done.\n");
end