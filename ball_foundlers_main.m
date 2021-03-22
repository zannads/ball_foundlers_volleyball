%ball_foundlers_main
global debug_track debug_jump;
debug_track = 0;
debug_jump = 0;

% create actions handler to manage the actions of the game.
a_h = actions_handler( cd, 'actions.mat');
% create video handler to manage the reader and players for the video, it
% also keeps memory of the last steps during tracking.
v_h = video_handler( a_h.get_videoname );
% create frame analyser to detect the best possible matches at every frame.
f_a = frame_analyser();

% the object action handler keeps also all the information about the camera
% and the video, if it doesn't have it or you want to redo it press 1 and
% the calibration steps will be done.
str = input( 'Do you need to calibrate?  ' );
if str
    a_h = ball_foundlers_calibration( a_h );
end

% One of the first steps we need to do the tracking is learning the 
% background to detect the foreground objects.
f_a = ball_foundlers_train_background( a_h, v_h, f_a );


% Now we can do action detection and 3d transformation of the requested
% action.
str = input( 'Which action do you want to execute?  ' );
while str
    
    [a_h, v_h, f_a] = ball_foundlers_ball_track( a_h, v_h, f_a, str );
    str = input( 'Which action do you want to execute?  ' );
    close all;
end
