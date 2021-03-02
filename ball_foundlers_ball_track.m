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

v_h = video_handler();
f_a = frame_analyser();

count = 1;

while count < 800+1
    if ~ mod( count, 100 )
        disp( "Learning backgorund" );
    end
    v_h.frame = readFrame(v_h.reader);
    
    mask = f_a.learn_background(v_h.frame);
    count = count+1;
end


%%
actions = load( 'actions.mat' );

% for actions

%starting moment of the first action
    % I should listen to whistle
%count = actions.action_1.starting_frame;

v_h.reader.CurrentTime = actions.action_1.starting_time;
v_h = v_h.next_frame();

ball = v_h.start_action( actions.action_1.starting_side, actions.action_1.position_x, actions.action_1.position_y);
v_h = v_h.display_tracking( ball );

while( v_h.reader.CurrentTime <= actions.action_1.ending_time )
    v_h = v_h.next_frame();
    
    %analysis to perfrom when the action is on
    last_known.position = ball.image_coordinate{end};
    last_known.radii = ball.radii{end};
    [f_prop] = f_a.foreground_analysis( v_h.frame, last_known );
    [h_prop] = f_a.hsv_analysis( v_h.frame, last_known );
    [s_prop] = f_a.step_analysis( v_h.frame, v_h.old_frame{1}, last_known );
    
    ball = ball.predict_location( v_h.frame );
    %last one is the predicted
    
    ball = ball.assignment( f_prop, h_prop, s_prop );
    
    % display video
    v_h = v_h.display_tracking( ball, f_prop, s_prop);
end
% referee has whistle again, ball has touched ground
v_h = v_h.end_action();



