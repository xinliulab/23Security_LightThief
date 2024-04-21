%% probing calculation
clearvars
path(path, "./legendflex-pkg-master/setgetpos_V1.2");
path(path, "./legendflex-pkg-master/legendflex");
path(path, "./matlab-hatchfill2-master");
close all

Nant = [32, 256, 1024]; % [16, 64, 256, 1024]; 
Nclient = [1,8];         % [1,8];
brp_enable = [0, 1];

K=2;
aco_ref_beam_probes = 32;
aco_probes = 3*Nant +1; %Nant+4*(Nant-1);
swift_probes = 3*log2(Nant);
ubig_probes = 4*K+8;
beacon_slots = 64;
abft_slots = 8;
ssw_per_abft = 16;

fs = 1760e6;
stf_samples = 2176;
ce_samples = 1152;
phy_header_samples = 1024;
phy_header_time = (stf_samples + ce_samples + phy_header_samples)/fs;
trn_subfield_samples = 640;
agc_subfield_samples = 320;
mac_min_samples = 9280;

ssw_frame_time = phy_header_time + (26*8)/(27.5e6/2); % 26 bytes sent through Control PHY
trn_time = @(x) (x>0)*(phy_header_time + (mac_min_samples + x*agc_subfield_samples +...
    ce_samples*(1+floor((x-1)/4)) + x*trn_subfield_samples)/fs); % no MAC payload
beacon_int_time = 100e-3;

swift_latency = zeros(length(Nclient), length(Nant), length(brp_enable));
aco_latency = zeros(length(Nclient), length(Nant), length(brp_enable));
ubig_latency = zeros(length(Nclient), length(Nant), length(brp_enable));

for ii=1:length(Nclient)
    for jj=1:length(Nant)
        for kk=1:length(brp_enable)
            swift_clients_side = 0;
            swift_ap_side = 0;
            % SWIFT: client-side training
            if brp_enable(kk) == 0
                % SLS only
                r = mod(swift_probes(jj)*Nclient(ii), abft_slots*ssw_per_abft);
                q = floor(swift_probes(jj)*Nclient(ii) / (abft_slots*ssw_per_abft));
                swift_clients_side = swift_probes(jj)*ssw_frame_time + ...
                beacon_int_time*(q-1*(r==0));
            else
                if swift_probes(jj)*Nclient(ii) <= abft_slots*ssw_per_abft % SLS
                    swift_clients_side = ssw_frame_time*swift_probes(jj)*Nclient(ii);
                else % SLS + BRP
                    swift_clients_side = ssw_frame_time*abft_slots*ssw_per_abft;
                    % asuume every client gets an amount of equal beam training slots
                    remaining_probes_per_client = swift_probes(jj) - floor(abft_slots*ssw_per_abft/Nclient(ii));
                    % up to 64 TRN subfields in a data frame
                    r = mod(remaining_probes_per_client,64);
                    q = floor(remaining_probes_per_client/64);
                    swift_clients_side = swift_clients_side + Nclient(ii)*(q*trn_time(64) + trn_time(r));
                end
            end
            % SWIFT: ap-side training
            r = mod(swift_probes(jj),beacon_slots);
            q = floor(swift_probes(jj)/beacon_slots);
            swift_ap_side = swift_probes(jj)*ssw_frame_time + beacon_int_time*(q-1*(r==0));
            swift_latency(ii,jj,kk) = max(swift_clients_side, swift_ap_side);
            
            aco_clients_side = 0;
            aco_ap_side = 0;
            % ACO: client-side training
            if brp_enable(kk) == 0
                % SLS only
                n = (aco_ref_beam_probes + aco_probes(jj))*Nclient(ii);
                r = mod(n , abft_slots*ssw_per_abft);
                q = floor(n / (abft_slots*ssw_per_abft));
                aco_clients_side = n*ssw_frame_time + beacon_int_time*(q-1*(r==0));
            else
                % each client needs to acquire a reference beam before BRP
                q = floor(aco_ref_beam_probes*Nclient(ii) / (abft_slots*ssw_per_abft));
                r = mod(aco_ref_beam_probes*Nclient(ii), abft_slots*ssw_per_abft);
                aco_clients_side = ssw_frame_time*aco_ref_beam_probes*Nclient(ii) + ...
                    beacon_int_time*(q-1*(r==0));
                % perform ACO in BRP 
                r = mod(aco_probes(jj),64);
                q = floor(aco_probes(jj)/64);
                aco_clients_side = aco_clients_side + Nclient(ii)*(q*trn_time(64) + trn_time(r));
            end
            % ACO: ap-side training
            if brp_enable(kk) == 0
                r = mod(aco_probes(jj),beacon_slots);
                q = floor(aco_probes(jj)/beacon_slots);
                aco_ap_side = aco_probes(jj)*ssw_frame_time + ...
                beacon_int_time*(q-1*(r==0));
            else
                if aco_probes(jj) <= beacon_slots
                    aco_ap_side = aco_probes(jj)*ssw_frame_time;
                else
                    n = aco_probes(jj) - beacon_slots;
                    r = mod(n,64);
                    q = floor(n/64);
                    aco_ap_side = beacon_slots*ssw_frame_time + q*trn_time(64) + trn_time(r) ;
                end
            end
            aco_latency(ii,jj,kk) = max(aco_clients_side, aco_ap_side);


            ubig_clients_side = 0;
            ubig_ap_side = 0;
            % UbiG: client-side training
            if brp_enable(kk) == 0
                % SLS only
                r = mod(ubig_probes*Nclient(ii), abft_slots*ssw_per_abft);
                q = floor(ubig_probes*Nclient(ii) / (abft_slots*ssw_per_abft));
                ubig_clients_side = ubig_probes*ssw_frame_time + ...
                beacon_int_time*(q-1*(r==0));
            else
                if ubig_probes*Nclient(ii) <= abft_slots*ssw_per_abft % SLS
                    ubig_clients_side = ssw_frame_time*ubig_probes*Nclient(ii);
                else % SLS + BRP
                    ubig_clients_side = ssw_frame_time*abft_slots*ssw_per_abft;
                    % asuume every client gets an amount of equal beam training slots
                    remaining_probes_per_client = ubig_probes - floor(abft_slots*ssw_per_abft/Nclient(ii));
                    % up to 64 TRN subfields in a data frame
                    r = mod(remaining_probes_per_client,64);
                    q = floor(remaining_probes_per_client/64);
                    ubig_clients_side = ubig_clients_side + Nclient(ii)*(q*trn_time(64) + trn_time(r));
                end
            end
            % UbiG: ap-side training
            r = mod(ubig_probes,beacon_slots);
            q = floor(ubig_probes/beacon_slots);
            ubig_ap_side = ubig_probes*ssw_frame_time + beacon_int_time*(q-1*(r==0));
            ubig_latency(ii,jj,kk) = max(ubig_clients_side, ubig_ap_side);
        end
    end
end

wo_brp = [swift_latency(:,:,1); aco_latency(:,:,1)].'; % ant, nclients
w_brp = [swift_latency(:,:,2); aco_latency(:,:,2)].'; % ant, nclients

% aco_probing = aco_latency(:,:,1); save("aco_probing.mat", "aco_probing");
% swift_probing = swift_latency(:,:,1); save("swift_probing.mat", "swift_probing");
% ubig_probing = ubig_latency(:,:,1); save("ubig_probing.mat", "ubig_probing");


%% ACO latency
n = [32, 256, 1024]; %[32,1024]; %2.^[5:10];
ACOcomputation = zeros(1,length(n));
for ii=1:length(n)
    a = randn(4,n(ii),10000);
    tStart = tic;
    b = angle(fft(a.^2, [], 1));
    tEnd = toc(tStart);
    ACOcomputation(ii) = tEnd/10000;
end
figure(1); plot(ACOcomputation); hold on ;
save("ACOcomputation.mat", "ACOcomputation");
%% CAEMO computational latency
n = [32, 256, 1024]; %[32,1024]; 
k = [1:3];
% az = [-80:80];
FTPcomputation = zeros(length(k), length(n));
for ii=1:length(n)
    for jj=1:length(k)
        N = n(ii);
        K = k(jj);
        pa = phased.URA('Size',round(sqrt(N)), 'ElementSpacing', PA.LAM/2);
        [BW,Ang] = beamwidth(pa,PA.FREQ);
        M = round(K*log2(N));
        Q = round((180/BW)^2); %length(az);
        
        clear a;
        a = randn(M*Q*K,5000);
        b = randn(K,5000);
        c = randn(K,1);
        d = randn(N*K,5000);
        tStart = tic;
        % dot product of Mx1 vectors Q*K times  
        e = (a'*a(:,1));
        % calculate tx beam gains,  dot product of Nx1 vectors K times
        f = d'*d(:,1);
        % divide out known tx beam gain K times
        g = b./c;
        % average over peaks
    %     f = mean(e);
        tEnd = toc(tStart);
        FTPcomputation(jj, ii) = tEnd/5000;% + n_beams*1000e-6; % optimization 100 us
    end
end
figure(1); plot(FTPcomputation.'); hold on ;
save("FTPcomputation.mat", "FTPcomputation");
%% 
A = randn(64,81);
b = randn(64,1);
n=81;
cvx_begin quiet
variable x(n) complex
                tStart = tic;
minimize( norm(A*x-b)+0.2*norm(x,1) )
                tEnd = toc(tStart)
cvx_end
tStart = tic;
 tEnd = toc(tStart)