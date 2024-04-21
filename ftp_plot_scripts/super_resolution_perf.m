% close all;
fontsize = 15;
fig_size = [1 1 6 3];
linewidth = 2.5;
markersz = 8;
fname_11 = "../figures/ofdm_superres.pdf";

load("./H.mat");
fftsize = size(H,1);
b = ifft(H);
hh = [b(end-fftsize/2+1:end); b(1:fftsize/2)];
fs = 200e6;
res = 1/fs/10;
Analog_BW = 160e6;
t = [0:fftsize-1]./fs;
[M,I] = max(abs(hh));
intial_tau = I/fs;
        
t_search = intial_tau + [-20e-9:res:20e-9];
[T2,Tau2] = ndgrid(t,t_search);
h_sinc_mat2 = sinc(Analog_BW*(T2-Tau2)); % get sincs at tau TOF

A = h_sinc_mat2;
b = hh./max(abs(hh)); %h_sinc_noise(1:length(h_sinc));
n = size(A,2);
gamma = logspace( -1, 0, 20 );
x_final = zeros(n,length(gamma));

mse_error = zeros(2,1);
k = 12;
cvx_begin quiet
    variable x(n) complex
    minimize( norm(A*x-b)+gamma(k)*norm(x,1) )
cvx_end

h_est = x;
[~,loc,~,prominence] = findpeaks(abs(h_est)./max(abs(h_est)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);
[M,I] = maxk(prominence,2);

loc = loc(I);
tau = t_search(loc);
[T,Tau] = ndgrid(t,tau);
h_sinc_mat = sinc(Analog_BW*(T-Tau));
h_est2 = lsqminnorm(h_sinc_mat, hh, 1e-10,"warn");
h_sinc_mat_wt3 = h_sinc_mat*diag(h_est2);
h_sinc2 = sum(h_sinc_mat_wt3,2);

% for plotting
t2 = [0:0.1:fftsize-1]./fs;
[T2,Tau2] = ndgrid(t2,tau);
h_sinc_mat2 = sinc(Analog_BW*(T2-Tau2)); % get sincs at tau TOF
h_sinc_mat_wt5 = h_sinc_mat2*diag(h_est2);
h_sinc2_plot = sum(h_sinc_mat_wt5,2);

fig = figure('Units','inches', 'Position', fig_size);
shift = fftsize/2/fs;
scale = max(abs(hh));
stem((tau(1)-shift)*1e9,abs(h_est2(1))./scale, 'b-.', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
plot((t2-shift)*1e9,abs(h_sinc_mat_wt5(:,1))./scale, 'b-.', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
if length(tau)>1
    stem((tau(2)-shift)*1e9,abs(h_est2(2))./scale, 'r:', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
    plot((t2-shift)*1e9,abs(h_sinc_mat_wt5(:,2))./scale, 'r:', 'linewidth',linewidth,'MarkerSize',markersz); hold on;
end
%                 plot(t2*1e9,abs(h_sinc2_plot), 'mo-', 'linewidth',1); hold on;
plot((t-shift)*1e9,abs(h_sinc2)./scale, 'gs-', 'linewidth',linewidth); hold on;
plot((t-shift)*1e9,abs(hh)./scale, 'ko-', 'linewidth',linewidth);
hold off; grid on; grid minor;
%                 title(sprintf("MSE=%.3f",mse_error(jj)));
% ylim([-40,10]);
xlim(([t_search(1)-5e-9 t_search(end)+2e-9] - shift)*1e9);
xlabel('ToF (ns)'); ylabel('Normalized magnitude')
set(gca,'fontsize',fontsize)
if length(tau)>1
    legend('','Est. path 1','', 'Est. path 2', 'Fitted CIR', 'Measured CIR')
    %                     legend('Est. path 1','Est. path 2', 'Fitted CIR', 'Measured CIR')
else
    legend('','Est. path 1','Fitted CIR','Mixed CIR')
end
exportgraphics(fig,fname_11,'Resolution',300);
