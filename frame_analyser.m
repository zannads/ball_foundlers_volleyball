classdef frame_analyser
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        video_reader = [];
        video_player = [];
        mask_player = [];
        f_detector = [];
        blob_analyser = [];
        h_tracker = [];
        block_matcher = [];
        template_matcher = [];
        ball = [];
        
        old_frame = [];
    end
    
    
    methods
        %% Create System Objects
        % Create System objects used for reading the video frames, detecting
        % foreground objects, and displaying results.
        % taken from Motion-Based Multiple Object Tracking
        % Copyright 2014 The MathWorks, Inc.
        function obj = frame_analyser()
            % Initialize Video I/O
            % Create objects for reading a video from a file, drawing the tracked
            % objects in each frame, and playing the video.
            
            % Create a video reader.
            obj.video_reader = VideoReader('/Users/denniszanutto/Downloads/Pallavolo_1.mp4');
            %   obj.reader.CurrentTime = 180;
            % Create two video players, one to display the video,
            % and one to display the foreground mask.
            % obj.mask_player = vision.VideoPlayer('Position', [740, 400, 700, 400]);
            obj.video_player = vision.VideoPlayer('Position', [20, 400, 700, 400]);
            
            % Create System objects for foreground detection and blob analysis
            
            % The foreground detector is used to segment moving objects from
            % the background. It outputs a binary mask, where the pixel value
            % of 1 corresponds to the foreground and the value of 0 corresponds
            % to the background.
            
            obj.f_detector = vision.ForegroundDetector('NumGaussians', 3, ...
                'NumTrainingFrames', 500, 'MinimumBackgroundRatio', 0.7);
            
            % Connected groups of foreground pixels are likely to correspond to moving
            % objects.  The blob analysis System object is used to find such groups
            % (called 'blobs' or 'connected components'), and compute their
            % characteristics, such as area, centroid, and the bounding box.
            
            obj.blob_analyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
                'AreaOutputPort', true, 'CentroidOutputPort', true, ...
                'MinimumBlobArea', 400, 'MaximumBlobArea', 800);
            
            start_image = imread( '/Users/denniszanutto/Downloads/start_image.jpg');
            start_image_hsv = rgb2hsv(start_image);
            ball_starting_region = [290, 190, 16, 16];
            % using hsv tracking I create the object histogram
            obj.h_tracker = vision.HistogramBasedTracker;
            initializeObject(obj.h_tracker, start_image_hsv(:,:,1) , ball_starting_region);
            
            
            % using difference between frames
            obj.block_matcher = vision.BlockMatcher('ReferenceFrameSource',...
                'Input port','BlockSize',[720 1280]);
            obj.block_matcher.OutputValue = 'Horizontal and vertical components in complex form';
            
            % template matching for start of the action
            obj.template_matcher = vision.TemplateMatcher('ROIInputPort', true, ...
                'BestMatchNeighborhoodOutputPort', true);
            
            % I'll create the object whnen I hear the whistle, doen't make
            % sense to track i out of the actions
            obj.ball = [];
            
            obj.old_frame = [];
        end
        
        %% Foreground Analysis
        % The |foreground_analysis| function returns the centroids and the bounding boxes
        % of the probable ball.
        
        % The function performs motion segmentation using the foreground detector.
        % It then performs morphological operations on the resulting binary mask to
        % remove noisy pixels and to fill the holes in the remaining blobs.
        
        function [set] = foreground_analysis_bbox( obj, frame)
            
            % Detect foreground and build the struct.
            set.mask = obj.f_detector.step(frame);
            set.bboxes = cell(0);
            set.centroids = cell(0);
            
            % Apply morphological operations to remove noise and fill in holes.
            set.mask = imopen(set.mask, strel('rectangle', [3,3]));
            set.mask = imclose(set.mask, strel('rectangle', [15, 15]));
            set.mask = imfill(set.mask, 'holes');
            
            % Perform blob analysis to find connected components.
            [~, centroids, bboxes] = obj.blob_analyser.step(set.mask);
            
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
            
            % move to cells
            for idx = 1:size(bboxes, 1)
                set.bboxes{idx} = bboxes( idx, : );
                set.centroids{idx} = centroids( idx, :);
            end
        end
        
        function [set] = foreground_analysis( obj, frame)
            
            % Detect foreground and build the struct.
            mask = obj.f_detector.step(frame);
            
            % Apply morphological operations to remove noise and fill in holes.
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            set = arrange_prop( mask );          
        end
        
        function [obj] = learn_background( obj, frame )
            % Detect foreground.
            [~] = obj.f_detector.step(frame);
        end
        
        function [set] = hsv_analysis ( obj, frame )
            % try to look for yellows
            color = [0.15, 0.25];
            
            hsv_frame = rgb2hsv(frame);
            
            mask = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
            
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            set = arrange_prop( mask );
            % bbox = obj.h_tracker( hsv_frame(:,:,1) ); %#ok<NASGU>
        end
        
        function [set] = step_analysis( obj, frame )
            %analyssi between subsequnet frames
            mask = sum( abs( obj.old_frame-frame ), 3 ) > 20;
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            set = arrange_prop( mask );
            %motion = obj.block_matcher( frame, obj.old_frame ); %#ok<NASGU>
        end
        
        function obj = update_old( obj, frame )
            %update old frame for step analysis
            obj.old_frame = frame;
        end
        
        function obj = start_action( obj , frame )
            % when the referee whistle the action begins
            % Iìd like to use the template matcher, to find the first
            % instance of the ball.
            % now I just select it
            obj.ball = history_tracker();
            
            if( obj.ball.starting_side == 0 ) % it's on the far side
                %it should be visible
                
                % known info for now it is okay
                x = [839, 853];
                y = [29, 43];
                
                obj.ball.bbox{end} = [x(1), y(1), (x(2)-x(1)), (y(2)-y(1))];
                obj.ball.radii{end} = mean( [(x(2)-x(1)), (y(2)-y(1))])/2;
                obj.ball.image_coordinate{end} = [ ((x(1)+x(2))/2),  ((y(1)+y(2))/2)];
                obj.ball.state{end} = "known";
                obj.ball.length = obj.ball.length +1;
                obj.ball.total_visible_count = obj.ball.total_visible_count + 1;
                %reset
                obj.ball.consecutive_invisible = 0;
                
                %                 % template matching
                %                 target = imread( '/Users/denniszanutto/Downloads/target_image.jpg' );
                %                 roi_right_side = [740, 0, 525, 240];
                %
                %                 figure; imshow(frame); hold on; rectangle( 'Position', roi_right_side, 'EdgeColor', 'red');
                %
                %
                %                 pos = obj.template_matcher( rgb2gray( frame ), rgb2gray(target), roi_right_side );
                %                 viscircles( pos, 5 );
            else
                % it's out of the picture or covered
                
            end
        end
        
        function obj = end_action( obj )
            %again, the referee whistle, ball has touched the ground. ended
            %action
            
            %basically release the object ball that tracks history
            obj.ball = [];
            %save it
        end
        
        function obj = display_tracking( obj, frame )
            obj = obj.update_old(frame);
            
            if( ~isempty( obj.ball ) & ~isempty( obj.ball.bbox{end} ) )
                frame = insertObjectAnnotation(frame, 'rectangle', ...
                    obj.ball.bbox{end}, obj.ball.state{end});
                
                % Draw the objects on the mask.
                %                 mask = insertObjectAnnotation(mask, 'rectangle', ...
                %                     bboxes, label);
            end
            % Display the mask and the frame.
            %obj.mask_player.step(mask);
            obj.video_player.step(frame);
        end
        
        function out_ = is_tracking( obj )
            out_ = ~isempty( obj.ball );
        end
    end
end

