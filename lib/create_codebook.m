%% cs master
cb_size = 128;
beam_weight = cell(1,cb_size);
% q = randperm(length(PA.ACTIVE_ANT));
active_ant = PA.ACTIVE_ANT;
for ii=1:cb_size
%     % 1D
%     mag = zeros(32,1);     % turn off all antennas
% %     q = randperm(length(PA.ACTIVE_ANT));
% %     active_ant = PA.ACTIVE_ANT(q(1:8));
%     mag(active_ant) = 7*ones(length(active_ant),1);
%     %     mag = 7*(rand(32,1)>0.5);
%     psh = zeros(32,1);
%     p = randi([0 3],6,1);
%     psh([8 6 22 24]) = p(1)*ones(4,1);
%     psh([3 1 7 23 17 19]) = p(2)*ones(6,1);
%     psh([4 2 5 21 18 20]) = p(3)*ones(6,1);
%     psh([12 11 9 26 27 28]) = p(4)*ones(6,1);
%     psh([10 13 16 32 29 25]) = p(5)*ones(6,1);
%     psh([15 14 30 31]) = p(6)*ones(4,1);

    % 2D
    mag = zeros(32,1);
    mag(active_ant) = 7*ones(length(active_ant),1);
    psh = randi([0 3],32,1);
    beam_weight{ii} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
end
save("./codebooks/cs_master_2d.mat","beam_weight");
% plot_codebook("./codebooks/cs_master_2d.mat", [-90:2:90],[-50:2:50],PA)
% plot_codebook("./codebooks/cs.mat", 60480e6)
fprintf("Done.\n");
%% measure 2
ref_ant =1;
meas_ant = 2*ones(23,1);
cb_size = length(meas_ant)*4;
beam_weight = cell(1,cb_size);
cb_idx = 1;
for ii=1:length(meas_ant)
    for jj=1:4
        % etype registers (bit2,bit1,bit0) control which antenna is on/off
        mag = zeros(32,1);     % turn off all antennas
        mag(ref_ant) = 7;      % activate ref antenna
        mag(meas_ant(ii)) = 7; % activate measuring antenna

        psh = zeros(32,1);
        psh(meas_ant(ii)) = jj-1;
        beam_weight{cb_idx} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
        cb_idx = cb_idx + 1;
    end
end
save("./codebooks/measure_test.mat","beam_weight");
%% test codebook
cb_size = 32; 
beam_weight = cell(1,cb_size);
for ii=1:cb_size
    psh = 0*ones(32,1);
    mag = zeros(32,1); % turn off all antennas 
%     if ii<=10
%         mag(1) = 7;
%     elseif ii<=20
%         mag(2) = 7;
%     else 
%         mag(1:2) = 7;
%     end
    
    mag(ii) = 7; % activate ref antenna 
%     mag([1 13 17 29]) = 7*ones(4,1);
    beam_weight{ii} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
end
save("./codebooks/test.mat","beam_weight");
% plot_codebook("./codebooks/test.mat", 60480e6)
fprintf("Done.\n");

%% test codebook 2
ant=ones(15,1); 
cb_size = length(ant)*4;
beam_weight = cell(1,cb_size);
idx = 1;
for ii=1:length(ant)
%     mag = zeros(32,1); % turn off all antennas 
% %     mag(ant(ii)) = 7;
%     mag(1) = 7;
%     psh = 0*ones(32,1);
%     psh(1) = mod(idx-1,4);
%     beam_weight{idx} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
%     idx = idx + 1;

%     mag = zeros(32,1); % turn off all antennas 
%     mag(ant(ii)) = 7;
%     mag(1) = 7;
%     psh = 0*ones(32,1);
%     beam_weight{idx} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
%     psh = 2*ones(32,1);
%     beam_weight{idx+1} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
%     idx = idx + 2;

    mag = zeros(32,1);
    mag(ant(ii)) = 7;
    for jj=1:4
        psh = mod(-(jj-1), 4)*ones(32,1);
        beam_weight{idx+jj-1} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
    end
    idx = idx + 4;
end
save("./codebooks/test2.mat","beam_weight");
% plot_codebook("./codebooks/test.mat", 60480e6)
%% directional codebook
fc = 60.48e9;
lam = physconst('LightSpeed')/fc;
pa = get_phased_array(fc);
nqbits = 2;
az = repmat([0 ],1,1);
% az = [-60:5:60];
cb_size = length(az); 
beam_weight = cell(1,cb_size);
for ii=1:cb_size
    ang = [az(ii); 0]; %[az;el]
    sv = steervec(pa.getElementPosition()/lam,ang,nqbits); 
    phase = sv2psh(sv);
    beam_weight{ii} = {int2str(7*ones(32,1)), int2str(phase), int2str(6*ones(8,1))};
end
save("./codebooks/directional.mat","beam_weight");
% plot_codebook("./codebooks/directional.mat", fc)  
%% Two-arm codebook
fc = 60.48e9;
lam = physconst('LightSpeed')/fc;
pa = get_phased_array(fc);
cb_size = 1; 
beam_weight = cell(1,cb_size);
ang1 = [-6; 0]; %[az;el]
ang2 = [-44; 0]; %[az;el]
sv1 = steervec(pa.getElementPosition()/lam,ang1);
sv2 = steervec(pa.getElementPosition()/lam,ang2);
phase = sv2psh(sv1+sv2);
for ii=1:cb_size
    beam_weight{ii} = {int2str(7*ones(32,1)), int2str(phase), int2str(6*ones(8,1))};
end
% sv2beam(sv1+sv2,[-90:1:90],[-50:1:50],PA,[""])
save("./codebooks/twoarm.mat","beam_weight");
%% exhaustive
fc = 60.48e9;
lam = physconst('LightSpeed')/fc;
pa = get_phased_array(fc, PA.ACTIVE_ANT);
nqbits = 2;
az = [-60:2:60];
el = [0];
CAL=1;

cb_size = length(az)*length(el); 
assert(cb_size<=128);
beam_weight = cell(1,cb_size);
cb_idx = 1;
tmp = zeros(cb_size, length(PA.ACTIVE_ANT));
for ii=1:length(az)
    for jj=1:length(el)
        ang = [az(ii); el(jj);]; %[az;el]
        sv = steervec(pa.getElementPosition()/lam,ang); 
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