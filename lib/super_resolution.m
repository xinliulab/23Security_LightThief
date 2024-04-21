function [maxk_pos, maxk_pks] = super_resolution(H,plotting, k_sets_)
    maxk_pos = -99*ones(3,size(H,2));
    maxk_pks = -99*ones(3,size(H,2)); 
    fftsize = size(H,1);
    for ii=1:size(H,2)
        b = ifft(H(:,ii));
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
        k_sets = [16];
        if nargin > 2
            k_sets = k_sets_;
        end
        min_mse = inf;
        for jj=1:length(k_sets)
            k = k_sets(jj);
            cvx_begin quiet
                variable x(n) complex
%                 tStart = tic; 
                minimize( norm(A*x-b)+gamma(k)*norm(x,1) )
%                 tEnd = toc(tStart)
                
%                 minimize( norm(A*x-b)+k*norm(x,2) )
            cvx_end
%             figure(88); subplot(4,5,jj); plot(abs(x)); 
%             x_final(:,k) = x;
            % test mse
            h_est = x;
            [~,loc,~,prominence] = findpeaks(abs(h_est)./max(abs(h_est)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);
            [M,I] = maxk(prominence,2);
%             assert(k~=14 | (k==14 & length(I)==2));
%             assert(k~=16 | (k==16 & length(I)==1));
            loc = loc(I);
            tau = t_search(loc);
            [T,Tau] = ndgrid(t,tau); 
            h_sinc_mat = sinc(Analog_BW*(T-Tau));
            h_est2 = lsqminnorm(h_sinc_mat, hh, 1e-10,"warn");
            h_sinc_mat_wt3 = h_sinc_mat*diag(h_est2);
            h_sinc2 = sum(h_sinc_mat_wt3,2);
            mse = sqrt(mean(abs(h_sinc2-hh).^2));
            mse_error(jj) = mse;
            
            if jj==1
               mse_reduction = inf;
               fprintf("%d, k=%d, MSE %.3f\n", ii, k, mse);
            else
               mse_reduction = 100*(mse_error(jj)-mse_error(jj-1))/mse_error(jj);
               fprintf("%d, k=%d, MSE %.3f, mse reduction %.1f %%\n", ii, k, mse,...
                   mse_reduction);
            end 
            if mse < min_mse & abs(mse_reduction) > 10
                min_mse = mse;
                maxk_pos(1:length(tau),ii) = tau./res;
                maxk_pks(1:length(h_est2),ii) = h_est2;
            end
            

            if plotting==1
                % for plotting
                t2 = [0:0.1:fftsize-1]./fs;
                [T2,Tau2] = ndgrid(t2,tau); 
                h_sinc_mat2 = sinc(Analog_BW*(T2-Tau2)); % get sincs at tau TOF
                h_sinc_mat_wt5 = h_sinc_mat2*diag(h_est2);
                h_sinc2_plot = sum(h_sinc_mat_wt5,2);
    
%                 figure(90+jj); clf;
                fig = figure('Position', [100 100 200*3 200*2]);
                linewidth = 2.5;
                markersz = 8;
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
                xlabel('Time (ns)'); ylabel('Normalized magnitude')
                set(gca,'fontsize',18)
                if length(tau)>1
                    legend('','Est. path 1','', 'Est. path 2', 'Fitted CIR', 'Measured CIR')
%                     legend('Est. path 1','Est. path 2', 'Fitted CIR', 'Measured CIR')
                else
                    legend('','Est. path 1','Fitted CIR','Mixed CIR')
                end
                exportgraphics(fig,"./figures/ofdm_superres.pdf",'Resolution',300);
            end

            if mse < 0.2
                break;
            end
        end 
        


%         cvx_begin
%             variable x(n) complex
%             minimize( norm(A*x-b)+gamma(k)*norm(x,1) )
%         cvx_end
%         x_final(:,k) = x;
%         h_est = x_final(:,k);
%         
%         % method 1
%         figure(6); clf; findpeaks(abs(h_est)./max(abs(h_est)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);
%         [~,loc,~,prominence] = findpeaks(abs(h_est)./max(abs(h_est)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);
%         [M,I] = maxk(prominence,2);
%         loc = loc(I);
%         tau = t_search(loc);
%         h_complex = h_est(loc)*max(abs(hh));
%         [T,Tau] = ndgrid(t,tau); 
%         h_sinc_mat = sinc(BW*(T-Tau)); % get sincs at tau TOF
%         % generate superposed channel from sincs
%         h_sinc_mat_wt = h_sinc_mat*diag(h_complex);
%         h_sinc = sum(h_sinc_mat_wt,2);
%         fprintf("Initial TOF (ns):\n"); disp([intial_tau]*1e9);
%         fprintf("Est TOF (ns):\n"); disp([tau]*1e9);
%         if length(tau)>1
%             fprintf("Relative TOF (ns):\n"); disp([tau(2)-tau(1)]*1e9);
%         end
%         % method 2
%         h_est2 = lsqminnorm(h_sinc_mat, hh, 1e-10,"warn");
%         h_sinc_mat_wt3 = h_sinc_mat*diag(h_est2);
%         h_sinc2 = sum(h_sinc_mat_wt3,2);
%         
%         maxk_pos(1:length(tau),ii) = tau./0.2e-9;
%         maxk_pks(1:length(h_est2),ii) = h_est2;
% 
% 
%         fprintf("MSE method1: %.3f\n", sqrt(mean(abs(h_sinc-hh).^2)));
%         fprintf("MSE method2: %.3f\n", sqrt(mean(abs(h_sinc2-hh).^2)));
%         
%         % for plotting
%         t2 = [0:0.1:1023]./BW;
%         [T2,Tau2] = ndgrid(t2,tau); 
%         h_sinc_mat2 = sinc(BW*(T2-Tau2)); % get sincs at tau TOF
%         h_sinc_mat_wt4 = h_sinc_mat2*diag(h_complex);
%         h_sinc_plot = sum(h_sinc_mat_wt4,2);
%         h_sinc_mat_wt5 = h_sinc_mat2*diag(h_est2);
%         h_sinc2_plot = sum(h_sinc_mat_wt5,2);
%         
%         
%         % figure(91); clf;
%         % stem(tau(1)*1e9,abs(h_complex(1)), 'b.-', 'linewidth',1); hold on;
%         % stem(tau(2)*1e9,abs(h_complex(2)), 'r.-', 'linewidth',1); hold on;
%         % plot(t2*1e9,abs(h_sinc_plot), 'mo-', 'linewidth',1);
%         % plot(t*1e9,abs(hh), 'ko-', 'linewidth',1);
%         % hold off; grid on; grid minor;
%         % % ylim([-40,10]);
%         % xlim([t_search(1)-50e-9 t_search(end)+50e-9]*1e9);
%         % xlabel('time (ns)'); ylabel('Channel Impulse Response')
%         % set(gca,'fontsize',13)
%         % legend('Est path 1', 'Est path 2', 'mixed sincs','mixed CIR')
%         
%         figure(92); clf;
%         stem(tau(1)*1e9,abs(h_est2(1)), 'b.', 'linewidth',1); hold on;
%         plot(t2*1e9,abs(h_sinc_mat_wt5(:,1)), 'b.-', 'linewidth',1); hold on;
%         if length(tau)>1
%             stem(tau(2)*1e9,abs(h_est2(2)), 'r.', 'linewidth',1); hold on;
%             plot(t2*1e9,abs(h_sinc_mat_wt5(:,2)), 'r.-', 'linewidth',1); hold on;
%         end
%         % plot(t2*1e9,abs(h_sinc2_plot), 'mo-', 'linewidth',1); hold on;
%         plot(t*1e9,abs(hh), 'ko-', 'linewidth',1);
%         hold off; grid on; grid minor;
%         % ylim([-40,10]);
%         xlim([t_search(1)-10e-9 t_search(end)+10e-9]*1e9);
%         xlabel('time (ns)'); ylabel('Channel Impulse Response')
%         set(gca,'fontsize',13)
%         legend('','','Est path 1', 'Est path 2','mixed CIR')
    end
end