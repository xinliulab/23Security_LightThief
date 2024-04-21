function bp = create_beam_pattern(cb_name,el_range,az_range,PA)
    %% read bf weights from codebook and calculate beam pattern
%     if nargin <=1 
%         az_range = [-60:60];
%         el_range = [-45:45];
%         fc = 60.48e9;
%     end
    fc = PA.FREQ;
    cal_phase = PA.PHASE_CAL;
    mag_cal_vec = PA.MAG_CAL;
    load(cb_name); % load variable beam_weight
    c = physconst('LightSpeed');
    cb_size = length(beam_weight);
    bp = zeros(cb_size, length(el_range), length(az_range));
    
%     if nargin > 4 
%         pa = get_phased_array(fc, subarray_idx);
%     else
%         pa = get_phased_array(fc);
%     end
    
    
    for ii=1:cb_size
%         assert(all(str2num(beam_weight{ii}{1})>0));
%         assert(all(str2num(beam_weight{ii}{3})>0));
        etype = str2num(beam_weight{ii}{1});
        psh = str2num(beam_weight{ii}{2});

        if length(etype) == sum(etype>0)
            pa = get_phased_array(fc);
%             sv = exp(1j*2*pi/4*psh)./exp(1j*cal_phase);

%             sv = exp(-1j*2*pi/4*psh)./exp(1j*cal_phase);
            mag = ones(32,1);           
            for jj=1:32
                mag(jj) = mag_cal_vec( (psh(jj)+1), jj);
            end
            sv = mag.*exp(-1j*2*pi/4*psh)./exp(1j*cal_phase);
        else
            subarray_idx = find(etype>0);
            pa = get_phased_array(fc,subarray_idx);
            sv = exp(-1j*2*pi/4*psh(subarray_idx))./exp(1j*cal_phase(subarray_idx));
        end
        
        
        [PAT,AZ_ANG,EL_ANG] = pattern(pa,fc,az_range,el_range,...
        'PropagationSpeed',c,'Type','power','Normalize',false,...
        'CoordinateSystem','polar','Weights',sv);
        bp(ii,:,:) = PAT;
    end
    % figure; imagesc(AZ_ANG,EL_ANG,PAT); colorbar;
    % viewArray(pa, "ShowIndex", "All", 'ShowNormals',true)
end
% [PAT,AZ_ANG,EL_ANG] = pattern(pa,fc,az_range,el_range,...
%         'PropagationSpeed',c,'Type','power','Normalize',false,...
%         'CoordinateSystem','polar','Weights',[sv sv./abs(sv)]);
% figure; plot(PAT./max(PAT));

%%
% c = physconst('LightSpeed');
% fc = 60.48e9;
% lam = c/fc;
% elementPos_x = zeros(1,32);
% elementPos_y = (lam/2)*[4 4 5 5 3 3 3 4 3 5 4 5 4 3 4 3 1 1 0 0 2 2 2 1 0 2 1 0 1 2 1 2];
% elementPos_z = (lam/2)*(5-[1 2 1 2 2 0 1 0 3 4 3 3 4 5 5 4 1 2 1 2 2 0 1 0 4 3 3 3 4 5 5 4]);
% elementPos = [elementPos_y; elementPos_z] - 2.5*lam/2;
% % figure; scatter(elementPos_y,elementPos_z, 'x'); hold on; scatter(elementPos(1,:), elementPos(2,:), 'o');
% pa = phased.ConformalArray('ElementPosition',[elementPos_x; elementPos]);
% ang = [30;0];
% nqbits = 2;
% sv = steervec(elementPos/lam,ang,nqbits);
% rand_sv = exp(1j*2*pi*rand(32,1));
% reg_idx = mod(angle(sv)./(2*pi/2^nqbits), 2^nqbits);
% figure;
% [PAT,AZ_ANG,EL_ANG] = pattern(pa,fc,[-60:60],[-45:45],...
%     'PropagationSpeed',c,'Type','power',...
%     'CoordinateSystem','polar','Weights',sv, "ShowArray", true);
% imagesc(AZ_ANG,EL_ANG,PAT); colorbar;
% 
% figure;
% pattern(pa,fc,[-180:180],20,...
%     'PropagationSpeed',c,'Type','powerdb',...
%     'CoordinateSystem','polar','Weights',sv)

