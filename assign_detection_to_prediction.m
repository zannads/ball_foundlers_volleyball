function match = assign_detection_to_prediction( match, varargin )

f_set = varargin{1};
h_set = varargin{2};
s_set = varargin{3};

% get the n  closest to prediction,
n = 10;
v_set = select_strongest( match, n, f_set, s_set);

if v_set.length
    % for every of them, compute J
    x = J_values( v_set, h_set );
    
    
    lambda = [1, 30];
    J = lambda * x';
    
    % take min J idx
    [~, n] = min( J ) ;
    
    % assign it to obj.ball
    match.position = v_set.centers{ n };
    match.radii = v_set.radii{ n };
else
    match = [];
end

end
