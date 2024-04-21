function sv2beam(sv,az,el,PA,legs)
    pa = get_phased_array(PA.FREQ); 
%     az = [-90:2:90]; 
%     el = [-50:2:50];
    n = size(sv,2);
    PAT = zeros(n, length(el), length(az));
    fig = figure('Position', [100 100 200*8 200*4]);
    for ii=1:n
        sv2 = exp(-1j*2*pi/4.*sv2psh(sv(:,ii)./exp(1j*PA.PHASE_CAL)));
        [PAT_,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
        'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
        'CoordinateSystem','polar','Weights',sv2);
        PAT(ii,:,:) = PAT_;

        subplot(2,n,ii);
        imagesc(AZ_ANG,EL_ANG,PAT_); colorbar; title(legs(ii));
        [C,I] = max(PAT_(:));
        [I1,I2] = ind2sub(size(PAT_),I);
        fprintf("max az=%d, el=%d\n",az(I2), el(I1));
        
        subplot(2,n,[n+1:2*n]);
        fontsize = 13;
        PAT_azcut = PAT_(find(EL_ANG==el(I1)),:);
%         PAT_azcut_db = db(PAT_azcut/max(PAT_azcut), 'power');
        PAT_azcut_db = db(PAT_azcut, 'power');
        polarplot(deg2rad(az), PAT_azcut_db, '-', 'LineWidth', 2, "MarkerSize", 8); hold on;
    end
    ax = gca;
    ax.ThetaDir = 'clockwise';
    set(gca,'ThetaZeroLocation','top','FontSize',fontsize)
    % thetaticks(-90:30:90);
    thetalim([-90 90]);
    rlim([-35 0]);
    legend(legs);
end


% % find angles from ACO
% PAT_ACO = squeeze(PAT(2,:,:));
% PAT_CAMEO = squeeze(PAT(1,:,:));
% % path ang 1
% [C,I] = max(PAT_ACO(:));
% [I1,I2] = ind2sub(size(PAT_ACO),I);
% fprintf("max az=%d, el=%d\n",az(I2), el(I1));
% % path ang 2
% PAT_ACO = squeeze(PAT(2,:,1:find(az==-20)));
% [C,I] = max(PAT_ACO(:));
% [I1,I2] = ind2sub(size(PAT_ACO),I);
% fprintf("max az=%d, el=%d\n",az(I2), el(I1));
% 
% fig = figure('Position', [100 100 200*2 200*2]);
% color = 'brg';
% fontsize = 14;
% linewidth = 2.5;
% markersz = 8;
% PAT_azcut = squeeze(PAT_CAMEO(find(EL_ANG==0),:));
% PAT_azcut_db = db(PAT_azcut, 'power');
% polarplot(deg2rad(az), PAT_azcut_db, ['b-'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
% polarplot(deg2rad(-8)*ones(1,2), [-35 0], ['k--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
% polarplot(deg2rad(-41)*ones(1,2), [-35 0], ['k--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
% ax = gca;
% % ax.RTickLabel = {""}; % remove ticklabels
% subtitle("Normalized gain (dB)", "Position",[0,-47]);
% ax.ThetaDir = 'clockwise';
% set(gca,'ThetaZeroLocation','top','FontSize',fontsize)
% % thetaticks(-90:30:90);
% thetalim([-90 90]);
% rlim([-35 0]);
% legend(["CAMEO", "Ground truth"], 'Location', 'northoutside', 'NumColumns',2, 'Fontsize',fontsize);
% exportgraphics(fig,"./figures/ofdm_beam.pdf",'Resolution',300);
