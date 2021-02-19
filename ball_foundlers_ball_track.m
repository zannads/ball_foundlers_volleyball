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
%training_frames = 500;

obj = setupSystemObjects();

count = 0;
% Detect moving objects, and track them across video frames.
while hasFrame(obj.reader)
    %%%%%%
    % just to skip the begninning and go where the match starts
    count = count+1;
    if( count == 501)
        obj.reader.CurrentTime = 130;
    end
    %%%%%
    
    frame = readFrame(obj.reader);
    [centroids, bboxes, f_mask] = foreground_analysis(obj, frame);
    [hsv_mask] = hsv_analysis(obj, frame);
    s_mask = [];
    if( count> 1)
        [s_mask] = stepper_analysis(obj, frame, old_frame );
    end
    
    obj.ball = obj.ball.predict_location(frame);
    %last one is the predicted 
%     if count == 400 
%         close all;
%         figure, imshow(frame); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%         figure, imshow(f_mask); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%         figure, imshow(hsv_mask); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%         figure, imshow(s_mask); hold on; rectangle('Position', obj.ball.bbox{end}, 'EdgeColor', 'yellow'); hold off;
%     end
    % now let's see if it make sens to make it known
    obj.ball = obj.ball.assignment( f_mask, hsv_mask, s_mask, frame, bboxes );
    
    
    % %     predictNewLocationsOfTracks();
    %     [assignments, unassignedTracks, unassignedDetections] = ...
    %         detectionToTrackAssignment();
    %
    %     updateAssignedTracks();
    %     updateUnassignedTracks();
    %     deleteLostTracks();
    %     createNewTracks();
    %
    %     displayTrackingResults();
    % Draw the objects on the frame.
    
    
    if( ~isempty(obj.ball.bbox{end}))
        tframe = insertObjectAnnotation(frame, 'rectangle', ...
            obj.ball.bbox{end}, obj.ball.state{end});
        
        % Draw the objects on the mask.
        %                 mask = insertObjectAnnotation(mask, 'rectangle', ...
        %                     bboxes, label);
    end
    % Display the mask and the frame.
    %obj.maskPlayer.step(mask);
    obj.videoPlayer.step(tframe);
    
    
    old_frame = frame;
end

%% Create System Objects
% Create System objects used for reading the video frames, detecting
% foreground objects, and displaying results.
% taken from Motion-Based Multiple Object Tracking
% Copyright 2014 The MathWorks, Inc.

function obj = setupSystemObjects()
% Initialize Video I/O
% Create objects for reading a video from a file, drawing the tracked
% objects in each frame, and playing the video.

% Create a video reader.
obj.reader = VideoReader('/Users/denniszanutto/Downloads/Pallavolo_1.mp4');
%   obj.reader.CurrentTime = 180;
% Create two video players, one to display the video,
% and one to display the foreground mask.
% obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);
obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);

% Create System objects for foreground detection and blob analysis

% The foreground detector is used to segment moving objects from
% the background. It outputs a binary mask, where the pixel value
% of 1 corresponds to the foreground and the value of 0 corresponds
% to the background.

obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
    'NumTrainingFrames', training_frames, 'MinimumBackgroundRatio', 0.7);

% Connected groups of foreground pixels are likely to correspond to moving
% objects.  The blob analysis System object is used to find such groups
% (called 'blobs' or 'connected components'), and compute their
% characteristics, such as area, centroid, and the bounding box.

obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', true, 'CentroidOutputPort', true, ...
    'MinimumBlobArea', 400, 'MaximumBlobArea', 800);

obj.ball = history_tracker();

end

%% Foreground Analysis
% The |foreground_analysis| function returns the centroids and the bounding boxes
% of the probable ball.

% The function performs motion segmentation using the foreground detector.
% It then performs morphological operations on the resulting binary mask to
% remove noisy pixels and to fill the holes in the remaining blobs.

function [centroids, bboxes, mask] = foreground_analysis(obj, frame)

% Detect foreground.
mask = obj.detector.step(frame);

% Apply morphological operations to remove noise and fill in holes.
mask = imopen(mask, strel('rectangle', [3,3]));
mask = imclose(mask, strel('rectangle', [15, 15]));
mask = imfill(mask, 'holes');
%[centers,radii,metric] = imfindcircles(mask, [5, 15] );
% Perform blob analysis to find connected components.
[~, centroids, bboxes] = obj.blobAnalyser.step(mask);

%try to remove not squared boxes
ratios = double(bboxes(:,4))./double(bboxes(:,3));
ratios = (ratios > 0.5 & ratios < 1.5);
if sum(ratios) >0
    centroids_ = centroids;
    bboxes_ = bboxes;
    centroids = zeros( sum(ratios), 2);
    bboxes = zeros(sum(ratios), 4);
    jdx = 1;
    for idx = 1:size(ratios, 1)
        centroids(jdx, :) = int32(centroids_(idx, :));
        bboxes(jdx, :) = int32(bboxes_(idx, :));
        jdx = jdx+1;
    end
else
    bboxes = [];
    centroids = [];
end



end

%%
function [mask] = hsv_analysis ( obj, frame )
% try to look for yellows
color = [0.15, 0.25];

hsv_frame = rgb2hsv(frame);

mask = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));

% this stuff should not be used again
%         if ~isempty(bboxes)
%             idexs = zeros( size(bboxes, 1), 1);
%             for idx =1:size( idexs, 1)
%                 x_1 = bboxes(idx, 1);
%                 y_1 = bboxes(idx, 2);
%                 x_2 = x_1 + bboxes(idx, 3)-1;
%                 y_2 = y_1 + bboxes(idx, 4)-1;
%                 if( x_1 < 0 | y_1 < 0 | x_2 > 1280 | y_2 > 720)
%                     disp('a');
%                 end
%             a = rgb2hsv( frame( y_1:y_2, x_1:x_2, : ) );
%             m = ( a(:, : , 1) > min(color) & a(:, : , 1) < max(color) );
%             idexs( idx) = sum( double(m), 'all')/  (size(m, 1)*size(m, 2)) ;
%             end
%             threshold = 0.8;
%             bboxes = bboxes( (idexs > threshold) , :);
%             centroids = centroids( (idexs > threshold), :);
%         end
end

%%
function [mask] = stepper_analysis( obj, frame, old_frame )
diff = rgb2gray( abs( old_frame-frame ) );


mask = diff > threshold ;
end

%% constants
function out = training_frames
out = 500;
end

function out = threshold
out = 50;
end
