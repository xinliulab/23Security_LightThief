% offset = 0.6; % [-pi:0.2:pi];
N_realizations = 100;
N = 100000;   % number of measurements
URA_size = [36, 64, 256, 1024];
M = sqrt(URA_size); % antenna size, per side
Nmeas = [1e2 1e3 1e4 1e5];
% max_accumulation_err = zeros(length(Nmeas), length(URA_size), N_realizations);
est_err = zeros(URA_size(end), length(Nmeas), length(URA_size), N_realizations);
est_err2 = zeros(URA_size(end), length(Nmeas), length(URA_size), N_realizations);

for jj=1:N_realizations
    rng(jj);
    path_ang = -45+90*rand(N,1);
    % ensure no wrapping around 2*pi (slides 28)
    rel_phase_adj_ant = exp(1j*pi*sin(pi*path_ang/180)); 
    for ii=1:length(Nmeas)
        % Per antenna, accumulating measurements into one complex number works 
        x = angle(mean(rel_phase_adj_ant(1:Nmeas(ii))));
        % assume the middle antenna as the reference antenna
        max_accumulation_err(ii, :, jj) = x*(2*(ceil(M/2)-1)); 
        
        for kk=1:length(URA_size)
            est_err(1:URA_size(kk), ii, kk, jj) = reshape(exp(1j*x*([0:M(kk)-1]-M(kk)/2)).*exp(1j*x*([0:M(kk)-1]-M(kk)/2).'), [], 1); 
            est_err2(1:URA_size(kk), ii, kk, jj) = reshape(exp(1j*x*[0:M(kk)-1]).*exp(1j*x*[0:M(kk)-1].'), [], 1); 
        end
    end
end

% fig = figure('Units','inches', 'Position', [1 1 16 4]);
% for kk=1:length(URA_size)
%     subplot(1,length(URA_size),kk)
%     tmp = mean(abs(angle(est_err(1:URA_size(kk),:,kk,:))), 4);
%     semilogx(Nmeas, median(tmp, 1)); hold on;
%     semilogx(Nmeas, max(tmp, [], 1), '--'); hold on;
%     xlabel("# measurements");
%     ylabel("estimation error (rad)");
%     legend(["median", "max"]);
%     title("URA size "+string(URA_size(kk)));
% end
% exportgraphics(fig,"~/Downloads/mmw-calibration-sim/figures/2.png",'Resolution',300);

data = [];
data.Nmeas = Nmeas;
data.URA_size = URA_size;
data.mean_err = zeros(length(Nmeas), length(URA_size)); % ref in the middle
data.mean_err2 = zeros(length(Nmeas), length(URA_size)); % ref in the corner
for kk=1:length(URA_size)
    tmp = squeeze(rms(angle(est_err(1:URA_size(kk),:,kk,:)), 1));
    tmp = mean(tmp,2);
    data.mean_err(:,kk) = tmp;

    tmp = squeeze(rms(angle(est_err2(1:URA_size(kk),:,kk,:)), 1));
    tmp = mean(tmp,2);
    data.mean_err2(:,kk) = tmp;
end
% save("d7.mat","data");
fig = figure('Units','inches', 'Position', [1 1 10 4]);
bar(data.mean_err); legend("array size "+string(data.URA_size));
set(gca, 'XTickLabel', string(data.Nmeas))
xlabel("Number of measurements"); ylabel("RMS estimation error (rad)");

fig = figure('Units','inches', 'Position', [1 1 10 4]);
bar([data.mean_err(end,:).' data.mean_err2(end,:).']); legend(["ref in the middle", "ref in the corner"]);
set(gca, 'XTickLabel', string(data.URA_size))
xlabel("Phased array size"); ylabel("RMS estimation error (rad)");



