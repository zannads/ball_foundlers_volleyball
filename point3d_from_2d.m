function point = point3d_from_2d( u, v, P, fix_coord_name, fix_coord_value )
%POINT3D_FROM_2D Gives back a struct with the 3 coordinates on the space
% for a given projection matrix and with one constraint coordinate.

%% setup
% I use symbolic toolbox
syms x y z k real

% build the equation from X to u
eq = [u == k*(P(1,1)*x + P(1,2)*y +P(1,3)*z + P(1,4) ), ...
    v == k*(P(2,1)*x + P(2,2)*y +P(2,3)*z + P(2,4) ), ...
    1 == k*(P(3,1)*x + P(3,2)*y +P(3,3)*z + P(3,4) )];

% substitute the constrained coordinate
eq = subs( eq, fix_coord_name, fix_coord_value );

%% solve
%switch between the different cases of which coordinates is fixed so we can
%solve by the remaining.
if strcmp( fix_coord_name, 'x' )
    % solve 
    [v_1, v_2, ~] = solve( eq, [y, z, k] );
    
    % save 
    point.x = fix_coord_value;
    point.y = double( v_1 );
    point.z = double( v_2 );
    
elseif strcmp( fix_coord_name, 'y' )
    %solve 
    [v_1, v_2, ~] = solve( eq, [x, z, k] );
    
    %save
    point.y = fix_coord_value;
    point.x = double( v_1 );
    point.z = double( v_2 );
    
else
    % solve
    [v_1, v_2, ~] = solve( eq, [x, y, k] );
    
    %save
    point.z = fix_coord_value;
    point.x = double( v_1 );
    point.y = double( v_2 );
    
end

end