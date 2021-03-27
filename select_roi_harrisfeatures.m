function temp_set = select_roi_harrisfeatures( set, rois )
%SELECT_ROI_HARRISFEATURES Keeps the cornerpoints that are inside the
%regions of interest and separets them into cells. 

%roi specified as set of cell with bbox inside
% set as cell 


    points = set.Location;
    temp_set = cell( size(rois, 1), 1);
    for jdx = 1:size(rois, 1)
        roi = rois(jdx, :);
        % get the points in the region
        in = ( points(:, 1)>= roi(1) ) & ( points(:,2) >= roi(2) ) & ...
        ( points(:, 1)<= roi(1)+roi(3) ) & ( points(:, 2)<= roi(2)+roi(4) );
    
        temp_set{jdx} = set( in );
        
    end
    
end