function [roi_mask, v_x, v_y] = extract_roi( mask, x_y, semi_width)
%%EXTRACT_ROI given a 2d array extract the region of interest with area
%%2*semi_width and center x_y

% get the indexes of the array
bound = bbox_from_circle( x_y, semi_width, 'vectorial', 'Limits', size( mask ) );

% mask is obtained from the bound
roi_mask = mask( bound(1):bound(2), bound(3):bound(4) );
% shift for upper-left point of roi-mask withrespect to original mask
v_x = bound(3);
v_y = bound(1);
end