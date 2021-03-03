function x = J_values( v_set, h_set )
if v_set.length == 0
    x = [0, 0];
    return;
end

% x1
distance_from_prev = cell2mat( v_set.d_prev );

% x2
color_ratio = zeros( v_set.length, 1);
for idx = 1: v_set.length
    [mask, ~, ~] = extract_roi( h_set.mask, v_set.centers{ idx }, v_set.radii{ idx } );
    
    color_ratio(idx) = 1 - sum( mask, 'all' )/ ( size(mask, 1)* size(mask, 2) );
end

x = [ distance_from_prev, color_ratio ];

end