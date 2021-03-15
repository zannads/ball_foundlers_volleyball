function f_a = ball_foundlers_train_background( a_h, v_h, f_a )
%BALL_FOUNDLERS_TRAIN_BACKGROUND Train the foreground object in the frame
%analyser object. 
% get training time
train_time = a_h.get_training_frames /v_h.reader.FrameRate;

v_h.reader.CurrentTime = train_time(1);
count = 1;
while v_h.reader.CurrentTime <= train_time(2)
    if ~ mod( count, 100 )
        % Jus t show it is working
        disp( "Learning background" );
    end
    v_h.frame = readFrame(v_h.reader);
    
    % pass the number of the frame for eventually dynamic learning rate
    [~] = f_a.learn_background(v_h.frame, count);
    count = count+1;
end
end
