function [point_1, point_2] = ball_foundlers_extract_points( name, str_frame )
ball_foundlers_save_manual_clicked( [] );

ball_foundlers_show( name, '2d', 'background', str_frame );

msgbox( strcat('The image has been open. Press the first point of the trajectory and the last one. ') );

str = [];
while ~strcmp( str, 'y')
    str = input( "Did you do it? ", 's');
end

action = load( name );
num_points = action.frame{end};

points = ball_foundlers_save_manual_clicked( [] );

point_1.dd_c = points( 1, :);
point_2.dd_c = points( 2, :);

for idx = 1:num_points
    p = action.position{ idx };
    if ~isempty( p )
        if p(1) == point_1.dd_c(1) & p(2) == point_1.dd_c(2)
            point_1.time = idx;
        end
        if p(1) == point_2.dd_c(1) & p(2) == point_2.dd_c(2)
            point_2.time = idx;
        end
    end
end
    
point_1.x = [];
point_1.y = [];
point_1.z = [];

point_2.x = [];
point_2.y = [];
point_2.z = [];

    acquired = 0;
    disp( 'As first point you selected');
    while ~acquired
        axis = input( "Insert constaint AXIS: ", 's');
        value = input( "at  ");
        
        if strcmp( axis, 'x' ) | strcmp( axis, 'y' ) | strcmp( axis, 'z' )
            acquired = 1;
            point_1.(axis) = value;
        end
    end
    
    acquired = 0;
    while ~acquired
        axis = input( "Insert constaint for point 2, AXIS: ", 's');
        value = input( "at  ");
        if strcmp( axis, 'x' ) | strcmp( axis, 'y' ) | strcmp( axis, 'z' )
            acquired = 1;
            point_2.(axis) = value;
        end
    end
    
    % I just miss 3d point!
    % now I fix them
    point_1.x = 9;
point_1.y = 3;
point_1.z = 2;

point_2.x = 0;
point_2.y = 4;
point_2.z = 1.6;
    
    % struct
    % point
    %   2d coordinate
    %   constraint type: x [] y[] z = 3
    %   3d coordinate
    %   frame idx from variable
    
end
