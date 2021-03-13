%ball_foundlers_main

% create actions handler to manage the actions of the game.
a_h = actions_handler( cd, 'actions.mat');
% create video handler to manage the reader and players for the video, it
% also keeps memory of the last steps.
v_h = video_handler( a_h.get_videoname );
% create frame analyser to detect the best possible matches at every frame.
f_a = frame_analyser();
str = input( 'Do you need to calibrate?  ' );
if str
    a_h = ball_foundlers_calibration( a_h );
end

f_a = ball_foundlers_train_background( a_h, v_h, f_a );

str = input( 'Which action do you want to execute?  ' );
while str
    
    [a_h, v_h, f_a] = ball_foundlers_ball_track( a_h, v_h, f_a, str );
    str = input( 'Which action do you want to execute?  ' );
end
