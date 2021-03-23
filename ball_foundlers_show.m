function ball_foundlers_show( ball, space, varargin )
% BALL_FOUNDLERS_SHOW Shows the tracked ball in an image.


if strcmp( space, '2d' )
    % extract interesting data
x_y = ball.get_known_positions;

    % when 2d is requested
    figure;
    
    if nargin > 2 && strcmp( varargin{1}, 'background' )
        % when I aslo have an image for the background I show it beneath.
        background = varargin{2};
        imshow( background );
        hold on;
        plot( x_y(:, 1), x_y(:, 2), 'or', 'LineWidth', 5);
        
    else
        % no image, thus I need to revert y axis
        hold on;
        
        lot( x_y(:, 1), -x_y(:, 2), 'or', 'LineWidth', 5);
    end
    
    return;
end

% 3d 
if strcmp( space, '3d' )
    pitch = volleyball_pitch;
    %now draw just the pitch
    pitch.draw();
    % the camera if possible
    R = varargin{1};
    O = varargin{2};
    a = ver( 'MATLAB' );
    if ~strcmp( a.Release, '(R2019b)')
        pose = rigid3d( R', O');
        [~] = plotCamera('AbsolutePose',pose,'Opacity',0, 'Size', 0.3);
    else
        plot3( O(1), O(2), O(3), 'or', 'MarkerSize', 3);
    end
    % the 3d trajectory of the ball
    line( ball.trajectory3d.x, ball.trajectory3d.y, ball.trajectory3d.z, ...
        'Color','k','LineWidth',3);
end
end