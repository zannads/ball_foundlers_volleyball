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

count = 0;
% Detect moving objects, and track them across video frames.
while hasFrame(obj.video_reader)
    %%%%%%
    % just to skip the begninning and go where the match starts
    count = count+1;
    if( count == 500+1)
        obj.video_reader.CurrentTime = 130;
    end
    %%%%%
 
    frame = readFrame(obj.video_reader);
    if ( count < (500+1) )
        obj = obj.learn_background(frame);
    end
    
    %starting moment of the first action
    % i should listen to whistle
    if count == 834
        obj = obj.start_action( frame );
        
    %analysis to perfrom when the action is on
    elseif obj.is_tracking()
        [f_prop] = obj.foreground_analysis( frame);
        [h_prop] = obj.hsv_analysis( frame);
        [s_prop] = obj.step_analysis( frame );
        
        obj.ball = obj.ball.predict_location(frame);
        %last one is the predicted
        
%         if count == 834
%             close all
%             figure, imshow(frame); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%             figure, imshow(f_mask); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%             figure, imshow(hsv_mask); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%             figure, imshow(s_mask); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%             figure, imshow(f_mask);[centers, radii] = imfindcircles(f_mask, [3, 15]); [~] = viscircles(centers,radii);
%             figure, imshow(hsv_mask);[centers, radii] = imfindcircles(hsv_mask, [3, 15]); [~] = viscircles(centers,radii);
%             figure, imshow(s_mask);[centers, radii] = imfindcircles(s_mask, [3, 15]); [~] = viscircles(centers,radii);
%         end
        % now let's see if it make sens to make it known
         obj.ball = obj.ball.assignment( f_prop, h_prop, s_prop );
        
    end
    
    % display video
    obj = obj.display_tracking( frame );
    
    % referee has whistle again, ball has touched ground
    if count == 865
        obj = obj.end_action();
        return ;
    end 
end







