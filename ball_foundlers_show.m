function ball_foundlers_show( name, space, varargin )
if ~ exist( name, 'file' )
    return;
end

action = load( name );
num_points = action.frame{end};

if strcmp( space, '2d' )
    figure; 
    
    if nargin > 2 & strcmp( varargin{1}, 'background' )
        background = varargin{2};
        
        imshow( background );
        
    end
    hold on;
    for idx = 1:num_points
        x_y = action.position{idx};
        if ~isempty( x_y )
            plot( x_y(1), x_y(2), 'or', 'LineWidth', 5 );
        end
    end
        
    
end

% 3d in future
if strcmp( space, '3d' )
    figure; 
end
end