function [ang_dot, ang_logbar] = get_cs_result(codebook_name, rss_pwr, az_range,el_range, PA) 
    %% CS
%     az_range = [-80:80];
%     el_range = [-45:45]; %[-45:45];
%     lam = physconst('LightSpeed')/fc;
    show_plot = 0;
    fc = PA.FREQ;
    % step 1: find out path angle using CS
    bp = create_beam_pattern(codebook_name,el_range,az_range,PA); % (cb_size,el,az)
    angle_est = zeros(length(el_range),length(az_range));
    % for testing
    for ii=1:length(el_range)
        for jj=1:length(az_range)
            theoretic_bp = bp(:,ii,jj);
            observed_rss = rss_pwr; %TODO: rssvec must be in terms of power
            angle_est(ii,jj) = dot(observed_rss/norm(observed_rss), ...
                theoretic_bp/norm(theoretic_bp));
        end
    end
    [C,I] = max(angle_est(:));
    [I1,I2] = ind2sub(size(angle_est),I);
    ang_dot = [az_range(I2); el_range(I1)]; %[az;el]
    
    A = reshape(bp, size(bp,1), []);
    y = rss_pwr;
    x0 = zeros(length(az_range)*length(el_range),1);
    x0(I) = 1;
%     x0 = pinv(A)*y;
    K = length(rss_pwr);
    sigma = 20;
    epsilon =  1.1*sigma*sqrt(K)*sqrt(1 + 2*sqrt(2)/sqrt(K));  
%     xp = l1qc_logbarrier(x0, A, [], y, epsilon, 1e-3);
%     [C,I] = max(xp); 
%     [I1,I2] = ind2sub(size(angle_est),I);
    ang_logbar = [az_range(I2); el_range(I1)]; %[az;el]
    
    if show_plot
        % 1. plot beam pattern for the given codebook
%         plot_codebook(codebook_name, fc);
        
        % 2. plot CS estimation result
        fprintf("ang_dot = (%.1f,%.1f), ang_logbar = (%.1f,%.1f)\n", ang_dot, ang_logbar);
        fig=figure;
        if length(el_range)>1
            subplot(2,1,1);imagesc(az_range,el_range,angle_est); colorbar;
%             subplot(2,1,2);imagesc(az_range,el_range,reshape(xp,el_range,az_range)); colorbar;
        else
            plot(az_range, [angle_est(1,:).' ]); legend(["dot prod"]);
        end
        title(sprintf("CS angle estimation"));
        ylabel("Elevation (deg)");
        xlabel("Azimuth (deg)");
    
%         % verify beamforming direction
%         figure(3);
%         [PAT,AZ_ANG,EL_ANG] = pattern(pa,fc,az_range,el_range,...
%             'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',false,...
%             'CoordinateSystem','polar','Weights',sv);
%         imagesc(AZ_ANG,EL_ANG,PAT); colorbar; hold on;
%         plot(path_angle_az,path_angle_el,'kx',"MarkerSize",10);
%         title(sprintf("Beamforming direction (az,el)=(%.2f,%.2f)",path_angle_az,path_angle_el));
%         ylabel("Elevation (deg)");
%         xlabel("Azimuth (deg)");
    end
end