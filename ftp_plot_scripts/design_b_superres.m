% run('cvx-w64/cvx/cvx_setup.m')
% close all
BW = 200e6; % Analog bandwidth (Hz)
fs = 10*BW; % Sample rate (Hz)
SNR = 20;
c  = 3e8;   % speed of light (m/s)
dist = [6, 6.5]; % per-beam channel Distance of Flight (m)
tau = dist/c; % Per-beam channel Time of Flight (ToF), measured during beam training
h_complex = [1*exp(1j*1.2), .75*exp(1j*2.3)]; % Cmplx attenuation of each constituent beam's channel

% STEP 1: create wireless channel using two paths and their sinc interpolation
t=(-100:1:200)/fs;
% t=(0:1:128)/fs;
[T,Tau] = ndgrid(t,tau); 
h_sinc_mat = sinc(BW*(T-Tau)); % get sincs at tau TOF
% generate superposed channel from sincs
h_sinc_mat_wt = h_sinc_mat*diag(h_complex);
h_sinc = sum(h_sinc_mat_wt,2);
% figure; plot(abs(h_sinc))

t_search = [10:0.1:30]*1e-9;
[T2,Tau2] = ndgrid(t,t_search); 
h_sinc_mat2 = sinc(BW*(T2-Tau2)); % get sincs at tau TOF

% Add noise
N_SC = 512;
H_sinc = fft([h_sinc; zeros(N_SC-length(h_sinc),1)],N_SC) ;
H_sinc_noise = awgn(H_sinc, SNR, 'measured');
h_sinc_noise = ifft(H_sinc_noise,N_SC);
% figure; plot(abs(h_sinc_noise)); hold on; plot(abs(h_sinc));
[M,I] = max(abs(h_sinc_noise));

A = h_sinc_mat2;
b = h_sinc_noise(1:length(h_sinc));
n = size(A,2);
gamma = logspace( -2, 2, 20 );
x_final = zeros(n,length(gamma));
k=11;
cvx_begin
    variable x(n) complex
    minimize( norm(A*x-b)+gamma(k)*norm(x,1) )
cvx_end
x_final(:,k) = x;
h_est = x_final(:,k);
% % lsqminnorm doesn't work well 
% h_est = lsqminnorm(h_sinc_mat2, h_sinc_noise(1:length(h_sinc)), 1e-10,"warn");

% figure; findpeaks(abs(h_est)./max(abs(h_est)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);
[~,loc,~,prominence] = findpeaks(abs(h_est)./max(abs(h_est)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);

est_tau = t_search(loc);
[T,Tau] = ndgrid(t,est_tau);
h_sinc_mat5 = sinc(BW*(T-Tau));
h_est2 = lsqminnorm(h_sinc_mat5, b, 1e-10,"warn");

fprintf("TOF est (ns):\n");
disp([tau.' t_search(loc).']*1e9);
fprintf("Phase est (rad):\n");
disp(angle([h_complex.' h_est2]));
fprintf("Amp est error (abs):\n");
disp(abs([h_complex.'./h_complex(1) h_est2./h_est2(1)]));
fprintf("Max peak from the mixed CIR:\n");
disp([abs(h_sinc_noise(I)) angle(h_sinc_noise(I))])
% final_taps = h_est(loc);
% final_tof = t_search(loc);

est_complex_gain = h_est2.';
per_CIR = est_complex_gain.*h_sinc_mat2(:,loc);
est_CIR = sum(per_CIR,2);
true_CIR = h_sinc;


fig_size = [1 1 6 4];
% fig = figure('Position', [100 100 200*3 200*2]);
fig = figure('Units','inches', 'Position', fig_size);
color = 'brg';
fontsize = 20;
linewidth = 2.5;
markersz = 8;

scale = max(abs(true_CIR));
stem(est_tau(1)*1e9, abs(est_complex_gain(1))./scale, 'b-.', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
plot(t*1e9,abs(per_CIR(:,1))./scale, 'b-.', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
if length(tau)>1
    stem(est_tau(2)*1e9,abs(est_complex_gain(2))./scale, 'r:', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
    plot(t*1e9,abs(per_CIR(:,2))./scale, 'r:', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
end
%                 plot(t2*1e9,abs(h_sinc2_plot), 'mo-', 'linewidth',1); hold on;
% plot(t*1e9,abs(est_CIR)./scale, 'gs-', 'linewidth',linewidth); hold on;
plot(t*1e9,abs(true_CIR)./scale, 'ko-', 'linewidth',linewidth);
hold off; grid on; grid minor;
title("Channel Impulse Response");
% ylim([-40,10]);
xlim([t_search(1)-5e-9 t_search(end)+2e-9]*1e9);
xlabel('ToF (ns)'); ylabel('Normalized magnitude')
set(gca,'fontsize',fontsize)
if length(tau)>1
    legend('','Est. path 1','', 'Est. path 2', 'Measured CIR','Location','northwest')
    %                     legend('Est. path 1','Est. path 2', 'Fitted CIR', 'Measured CIR')
else
    legend('','Est. path 1','Fitted CIR','Mixed CIR')
end
exportgraphics(fig,"../figures/design_superres.png",'Resolution',300);


fig = figure('Units','inches', 'Position', fig_size);
tof = [10 20]*1e-9;
mag = [.8 .52];
BW = 400e6;
t = [5:0.5:35]*1e-9;
[T,Tau] = ndgrid(t,tof); 
h_sinc_mat = sinc(BW*(T-Tau)); 
h_sinc_mat_wt = h_sinc_mat*diag(mag);
h_sinc = sum(h_sinc_mat_wt,2);

stem(tof(1)*1e9, mag(1), 'b-.','LineWidth',linewidth,'MarkerSize',markersz);hold on;
stem((tof(2)+0.2e-9)*1e9, mag(2), 'r:','LineWidth',linewidth,'MarkerSize',markersz);hold on;
plot(t*1e9,abs(h_sinc),'ko-','LineWidth',linewidth,'MarkerSize',markersz); hold on;
grid on; grid minor;
title("Channel Impulse Response");
xlim([5 32]);
ylim([0 1]);
legend('Est. path 1', 'Est. path 2', 'Measured CIR','Location','northeast')
xlabel('ToF (ns)'); ylabel('Normalized magnitude')
set(gca,'fontsize',fontsize)
exportgraphics(fig,"../figures/design_superres2.png",'Resolution',300);

% [Q,R,p] = qr(h_sinc_mat2,0);
% semilogy(abs(diag(R)),'o')