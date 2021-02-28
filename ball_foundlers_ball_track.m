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
% Create System objects used for reading video, detecting moving objects,
% and displaying the results.

obj = frame_analyser();

count = 1;
% Detect moving objects, and track them across video frames.
while count < 800+1
    if ~ mod( count, 100 )
        disp( "Learning backgorund" );
    end
    frame = readFrame(obj.video_reader);
    
    mask = obj.learn_background(frame);
    count = count+1;
end


%%
actions = load( 'actions.mat' );

% for actions

%starting moment of the first action
    % I should listen to whistle
%count = actions.action_1.starting_frame;

obj.video_reader.CurrentTime = actions.action_1.starting_time;
frame = readFrame(obj.video_reader);
obj = obj.start_action( frame , actions.action_1.starting_side, actions.action_1.position_x, actions.action_1.position_y);
obj = obj.update_old( frame );
obj = obj.display_tracking( frame );

while( obj.video_reader.CurrentTime <= actions.action_1.ending_time )
    frame = readFrame(obj.video_reader);
    
    %analysis to perfrom when the action is on
    
    [f_prop] = obj.foreground_analysis( frame );
    [h_prop] = obj.hsv_analysis( frame );
    [s_prop] = obj.step_analysis( frame );
    
    obj.ball = obj.ball.predict_location(frame);
    %last one is the predicted
    
    obj.ball = obj.ball.assignment( f_prop, h_prop, s_prop );
    
    obj = obj.update_old(frame);
    % display video
    obj = obj.display_tracking( frame , f_prop, s_prop);
end
% referee has whistle again, ball has touched ground
obj = obj.end_action();



