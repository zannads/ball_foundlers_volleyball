%% ball_foundlers_ball_tracker

%this program should perform the tracking of a volleyball during a match, a
%couple of different approaches ae used in order to maximize the time
%instants where the ball is recognized

% both motion based tracking and object recoingission at every frame are
% performed in a (I hope ) smart way

%% MAIN ALGORITHM

% create object and initialize tracker
% train foreground object detector (saving it and eventulaly uploading it
% would be nice)

% then every frame since I decide to start to track he ball I have two
% options

% 1 foreground object detector looks for it, then the resulting blob is
% subtracted with the color analysis. I hope it leaves just the ball.
%if it's not enough, starting from a previous step on where was the ball
%could be interesting to look for it near to it

% Sometimes the ball will not be on the pitch. I discrad this result and I
% don't care. If I'll be good enough I'll complete the trajectories.

%%
a_h = actions_handler( cd, 'actions.mat');
v_h = video_handler( a_h.get_videoname );
f_a = frame_analyser();

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

warning( 'off' );
%starting moment of the first action
% I should listen to whistle
for idx = 1:a_h.total
    
    current = a_h.next();
    
    v_h.reader.CurrentTime = current.starting_time;
    v_h = v_h.next_frame();
    
    ball = v_h.start_action( current.starting_side, current.position_x, current.position_y);
    v_h = v_h.display_tracking( ball );
    
    while( v_h.reader.CurrentTime <= current.ending_time )
        v_h = v_h.next_frame();
        
        %analysis to perfrom when the action is on
        last_known.position = ball.image_coordinate{end};
        last_known.radii = ball.radii{end};
        
        f_a = f_a.write_report( v_h.frame, v_h.old_frame{1}, last_known );
        report = f_a.get_report();
        
%         [f_prop] = f_a.foreground_analysis( v_h.frame, last_known );
%         [h_prop] = f_a.hsv_analysis( v_h.frame, last_known );
%         [s_prop] = f_a.step_analysis( v_h.frame, v_h.old_frame{1}, last_known );
        
        ball = ball.predict_location( );
        %last one is the predicted
        
        ball = ball.assignment( report );
        
        % display video
        v_h = v_h.display_tracking( ball);
    end
    % referee has whistle again, ball has touched ground
    v_h = v_h.end_action();
end