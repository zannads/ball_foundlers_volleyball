%% ball_foundlers_ball_track
function [a_h, v_h, f_a] = ball_foundlers_ball_track( a_h, v_h, f_a, idx )
%BALL_FOUNDLERS_BALL_TRACK Tracks the volleyball in a video starting from
%given initial conditions.
% This program should perform the tracking of a volleyball during a match, a
%couple of different approaches are used in order to maximize the time
%instants where the ball is recognized.

% Motion based tracking is performed, using difference between frames and a
% mixture of gaussians to detect the object with respect to the foreground.

% imfindcircles prints a warning when the circles we are looking for are
% less then 5 pixels. Since ball radius is mostly around 10 pixels this message is
% printed many times.
warning( 'off' );

% acquire the action/service you are interested to
current = a_h.get_action( idx );

% I go the right moment in time on the reader
v_h.reader.CurrentTime = current.starting_time;
v_h = v_h.next_frame();

%save to show it at the end
start_frame = v_h.frame;

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
    % Everything that is found is placed inside the struct report 
    f_a = f_a.write_report( v_h.frame, v_h.old_frame{1}, last_known );
    v_h.report = f_a.get_report();
    
    debug = 0;
    if debug
        figure; imshow( v_h.report.foreground.mask );
        %figure;
    end
    
    % I add the prediction of the ball for this step, it is placed in the
    % last place of to the history, if I won't have any match this will
    % remain there under the label unknown.
    ball = ball.predict_location( );
    
    % Check if the prediction matches something from the analysis of the
    % frame
    [ball, flag] = ball.assignment( v_h.report );
    
    if flag
        % if the assingment went wrong, it means it hasn't found anything.
        
        % Let's take the images again and try to look fo blobs instead of
        % circles.
        f_a = f_a.deepen_report( last_known );
        v_h.report = f_a.get_report();
        
        % try asignment again
        [ball, ~] = ball.assignment( v_h.report );
    end
    
    %% not implemented
    % I look at the situation and eventualy I go back if I lost the ball!
    %         if ball.length > v_h.memory & ball.is_lost()
    %            ball.recover( v_h.prepare_for_recovery() );
    %         end
    %%
    % Display video
    v_h = v_h.display_tracking( ball );
end
% referee has whistle again, ball has touched ground and the action is
% ended. I save the history of the tracking and eventually show again the
% video at increased speed.
[~, a_h] = a_h.end_action( ball );

% now that I have tracked the ball I want to see it in 3d.
ball_foundlers_convert2dto3d( a_h.get_complete_action, start_frame );
end