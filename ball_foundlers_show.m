function ball_foundlers_show( data, space, varargin )
% BALL_FOUNDLERS_SHOW Shows the tracked ball in an image

%check data are correct
if isempty( data.detected )
    return;
end

% extract interesting data
data = data.detected;
num_points = size(data.frame, 1);

if strcmp( space, '2d' )
    % when 2d is requested
    figure;
    
    if nargin > 2 & strcmp( varargin{1}, 'background' )
        % when I aslo have an image for the background I whow it beneath.
        background = varargin{2};
        imshow( background );
        hold on;
        
        % plot all the points
        for idx = 1:num_points
            x_y = data.position{idx};
            if ~isempty( x_y )
                % callbacks were for eventual selection of the points
                plot( x_y(1), x_y(2), 'or', 'LineWidth', 5, 'ButtonDownFcn', @point_select_callback);
            end
        end
    else
        % no image, thus I need to revert y axis
        hold on;
        
        for idx = 1:num_points
            x_y = data.position{idx};
            if ~isempty( x_y )
                % callbacks were for eventual selection of the points
                plot( x_y(1), -x_y(2), 'or', 'LineWidth', 5, 'ButtonDownFcn', @point_select_callback);
            end
        end
    end
    
end

% 3d in future, actually is done in ball_foundler_convert2dto3d
if strcmp( space, '3d' )
    figure;
end
end