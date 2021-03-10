%% ball_foundlers_ball_tracker

%this program should perform the tracking of a volleyball during a match, a
%couple of different approaches are used in order to maximize the time
%instants where the ball is recognized.

% Motion based tracking is performed, using difference between frames and a
% mixture of gaussians to detect the object with respect to the foreground.

%% MAIN ALGORITHM

% create actions handler to manage the actions of the game.
a_h = actions_handler( cd, 'actions.mat');
% create video handler to manage the reader and players for the video, it
% also keeps memory of the last steps.
v_h = video_handler( a_h.get_videoname );
% create frame analyser to detect the best possible matches at every frame.
f_a = frame_analyser();

% I start by leaving the object frame analyser learning the background.
v_h.reader.CurrentTime = (a_h.training_frames(1)-1)/v_h.reader.FrameRate;
count = 1;
while v_h.reader.CurrentTime < a_h.training_frames(2)/v_h.reader.FrameRate
    if ~ mod( count, 100 )
        disp( "Learning background" );
    end
    v_h.frame = readFrame(v_h.reader);
    
    mask = f_a.learn_background(v_h.frame, count);
    count = count+1;
end
%%
% imfindcircles prints a warning when the circles we are looking for are
% less then 5 pixels. Since ball is mostly around 10 pixels this message is
% printed many times. 
warning( 'off' );
% To recognise the action another script should be used, in this case is
% done by hand.
for idx = 1:a_h.total
    % acquire the action
    current = a_h.get( idx );
    
    % I go the right moment
    v_h.reader.CurrentTime = current.starting_time;
    v_h = v_h.next_frame();
    
    %save for the end
    str_frame = v_h.frame;
    
    % I create the object to track the ball. 
    ball = a_h.start_action();
    % Startting positions are known, thus I'll show them.
    v_h = v_h.display_tracking( ball );
    
    % until the action ends
    while( v_h.reader.CurrentTime <= current.ending_time )
        % Go to the successive frame
        v_h = v_h.next_frame();
        
        % Important informations to reduce the search.
        last_known.position = ball.image_coordinate{end};
        last_known.radii = ball.radii{end};
        
        % Frame_analyser analyses the frame based on memory of
        % last_positions.
        f_a = f_a.write_report( v_h.frame, v_h.old_frame{1}, last_known );
        v_h.report = f_a.get_report();
        
        % I add the prediction of the ball for this step, in the last place
        % of to the history, if I won't have any match this will remain 
        % there.
        ball = ball.predict_location( );
       
        % Check if the prediction matches something from the analysis of the
        % frame
        [ball, flag] = ball.assignment( v_h.report );
        if flag 
            f_a = f_a.deepen_report( last_known );
            v_h.report = f_a.get_report();
            
            [ball, ~] = ball.assignment( v_h.report );
        end
        
        % I look at the situation and eventualy I go back! 
%         if ball.length > v_h.memory & ball.is_lost()
%            ball.recover( v_h.prepare_for_recovery() ); 
%         end
        
        % Display video
        v_h = v_h.display_tracking( ball );
    end
    % referee has whistle again, ball has touched ground and the action is
    % ended. I save the history of the tracking and eventually show again the video to
    % increase speed. 
    ball = a_h.end_action( ball );
    
    name = strcat( 'detected_action_', num2str( idx ), '.mat' );
    
    ball_foundlers_show( name, '2d', 'background', str_frame );
    
    msgbox( strcat('The image has been open. Press brush on the top right of the ', ...
    'figure. Select the starting point of the trajectory and then right click ', ... 
    'on it. Select export and then save the point as point_1. Same thing for the end', ...
    'save it as point_2 instead.') );
    
    str = [];
    while ~strcmp( str, 'y')
        str = input( "Did you do it? ", 's');
    end
    
    ball_foundlers_convert2dto3d( name, 1, point_1, point_2 );
end