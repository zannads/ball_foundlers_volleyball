function f_a = ball_foundlers_train_background( a_h, v_h, f_a )
train_time = a_h.get_training_frames /v_h.reader.FrameRate;
% I start by leaving the object frame analyser learning the background.
v_h.reader.CurrentTime = train_time(1);
count = 1;
while v_h.reader.CurrentTime <= train_time(2)
    if ~ mod( count, 100 )
        disp( "Learning background" );
    end
    v_h.frame = readFrame(v_h.reader);
    
    [~] = f_a.learn_background(v_h.frame, count);
    count = count+1;
end
end
