function pa = get_phased_array(fc, subarray_idx, ant_spacing)
    c = physconst('LightSpeed');
    lam = c/fc;
    % positions are in meters
    if nargin > 2
        spacing = ant_spacing;
    else
        spacing = (lam/2);
    end
    elementPos_x = zeros(1,32);
%     elementPos_y = (lam/2)*[4 4 5 5 3 3 3 4 3 5 4 5 4 3 4 3 1 1 0 0 2 2 2 1 0 2 1 0 1 2 1 2];
%     elementPos_z = (lam/2)*[4 3 4 3 3 5 4 5 2 1 2 2 1 0 0 1 4 3 4 3 3 5 4 5 1 2 2 2 1 0 0 1];
    elementPos_y = -spacing*[4 3 4 3 3 5 4 5 2 1 2 2 1 0 0 1 4 3 4 3 3 5 4 5 1 2 2 2 1 0 0 1];
    elementPos_z = spacing*[4 4 5 5 3 3 3 4 3 5 4 5 4 3 4 3 1 1 0 0 2 2 2 1 0 2 1 0 1 2 1 2];    
    elementPos = [elementPos_y + 2.5*spacing; elementPos_z - 2.5*spacing];
%     elementPos = [elementPos_y + 5*spacing; elementPos_z - 5*spacing];
    
    if nargin > 1 
        assert(all(subarray_idx>=1) && all(subarray_idx<=32), "get_phased_array sanity");
        pa = phased.ConformalArray('ElementPosition',[elementPos_x(subarray_idx); elementPos(:,subarray_idx)]);
    else
        pa = phased.ConformalArray('ElementPosition',[elementPos_x; elementPos]);
    end
    
    % figure; scatter(elementPos_y,elementPos_z, 'x'); hold on; scatter(elementPos(1,:), elementPos(2,:), 'o');
end

