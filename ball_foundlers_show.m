function ball_foundlers_show( data, space, varargin )
if isempty( data.detected )
    return;
end
data = data.detected;
num_points = size(data.frame, 1);

if strcmp( space, '2d' )
    figure;
    
    if nargin > 2 & strcmp( varargin{1}, 'background' )
        background = varargin{2};
        imshow( background );
        hold on;
        
        for idx = 1:num_points
            x_y = data.position{idx};
            if ~isempty( x_y )
                plot( x_y(1), x_y(2), 'or', 'LineWidth', 5, 'ButtonDownFcn', @point_select_callback);
            end
        end
    else
        % no image, but revert y axis
        hold on;
        
        for idx = 1:num_points
            x_y = data.position{idx};
            if ~isempty( x_y )
                plot( x_y(1), -x_y(2), 'or', 'LineWidth', 5, 'ButtonDownFcn', @point_select_callback);
            end
        end
    end
    
end

% 3d in future
if strcmp( space, '3d' )
    figure;
end
end