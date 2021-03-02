classdef frame_analyser
    %FRAME_ANALYSER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        f_detector = [];
        blob_analyser = [];
        h_tracker = [];
        block_matcher = [];
        template_matcher = [];
        
        debug = 0;
    end
    
    
    methods
        %% Create System Objects
        % Create System objects used for reading the video frames, detecting
        % foreground objects, and displaying results.
        % taken from Motion-Based Multiple Object Tracking
        % Copyright 2014 The MathWorks, Inc.
        function obj = frame_analyser()
            
            % Create System objects for foreground detection and blob analysis
            
            % The foreground detector is used to segment moving objects from
            % the background. It outputs a binary mask, where the pixel value
            % of 1 corresponds to the foreground and the value of 0 corresponds
            % to the background.
            
%             obj.f_detector = vision.ForegroundDetector('NumGaussians', 3, ...
%                 'NumTrainingFrames', 500, 'MinimumBackgroundRatio', 0.7);
            obj.f_detector = vision.ForegroundDetector('NumGaussians', 5, ...
                'AdaptLearningRate', 0, 'MinimumBackgroundRatio', 0.7);
            
            % Connected groups of foreground pixels are likely to correspond to moving
            % objects.  The blob analysis System object is used to find such groups
            % (called 'blobs' or 'connected components'), and compute their
            % characteristics, such as area, centroid, and the bounding box.
            
            obj.blob_analyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
                'AreaOutputPort', true, 'CentroidOutputPort', true, ...
                'MinimumBlobArea', 400, 'MaximumBlobArea', 800);
            
%             start_image = imread( '/Users/denniszanutto/Downloads/start_image.jpg');
%             start_image_hsv = rgb2hsv(start_image);
%             ball_starting_region = [290, 190, 16, 16];
%             % using hsv tracking I create the object histogram
%             obj.h_tracker = vision.HistogramBasedTracker;
%             initializeObject(obj.h_tracker, start_image_hsv(:,:,1) , ball_starting_region);
%             
            
            % using difference between frames
%             obj.block_matcher = vision.BlockMatcher('ReferenceFrameSource',...
%                 'Input port','BlockSize',[720 1280]);
%             obj.block_matcher.OutputValue = 'Horizontal and vertical components in complex form';
%             
            % template matching for start of the action
%             obj.template_matcher = vision.TemplateMatcher('ROIInputPort', true, ...
%                 'BestMatchNeighborhoodOutputPort', true);
%             
            obj.debug = 1;
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
        
        function [set] = foreground_analysis( obj, frame, last_known)
            l_r = 0.000000001;
            % Detect foreground and build the struct.
            mask = obj.f_detector.step(frame, l_r);
            
            % Apply morphological operations to remove noise and fill in holes.
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            set = obj.arrange_prop( mask, last_known );
            set.mask = mask;
        end
        
        function [mask] = learn_background( obj, frame )
            % Detect foreground.
            l_r = 0.005;
            [mask] = obj.f_detector.step(frame, l_r);
        end
        
        function [set] = hsv_analysis ( obj, frame, last_known )
            % try to look for yellows
            color = [0.15, 0.25];
            
            hsv_frame = rgb2hsv(frame);
            
            mask = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
            
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            % I think I can remove it from here
            set = obj.arrange_prop( mask, last_known );
            set.mask = mask;
            % bbox = obj.h_tracker( hsv_frame(:,:,1) ); %#ok<NASGU>
        end
        
        function [set] = step_analysis( obj, frame, old_frame, last_known )
            %analyssi between subsequnet frames
            mask = sum( abs( old_frame-frame ), 3 ) > 20;
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            set = obj.arrange_prop( mask, last_known );
            set.mask = mask;
            %motion = obj.block_matcher( frame, obj.old_frame ); %#ok<NASGU>
        end
        
        function set_ = arrange_prop( obj, mask, last_known  )
            %set_.mask = mask;
            [mask, v_x, v_y] = obj.extract_roi( mask, last_known.position );
            radius = last_known.radii;
            m_r = min( max( floor(0.5*radius), 3), 10) ;
            M_r = max( min( ceil(1.5*radius), 15), 5);
            [centers, radii] = imfindcircles(mask, [m_r, M_r]);
            
            set_.length = size( centers, 1);
            set_.centers = cell( set_.length, 1 );
            set_.radii = cell( set_.length, 1 );
            for idx = 1:size( centers, 1)
                set_.centers{idx} = centers( idx, : ) + [v_x, v_y];
                set_.radii{idx} = radii( idx, : );
            end
        end
        
        function [roi_mask, v_x, v_y] = extract_roi( obj, mask, x_y )
           
            x_1 = max( floor( x_y(1) -100 ), 1 );        % leftmost point
            y_1 = max( floor( x_y(2) -100 ), 1 );        % leftmost point
            x_2 = min( floor( x_y(1) +100 ), size(mask, 2) );        % leftmost point
            y_2 = min( floor( x_y(2) +100 ), size(mask, 1) );        % leftmost point
            
            roi_mask = mask( y_1:y_2, x_1:x_2 );
            v_x = x_1;
            v_y = y_1;
        end
    end
end

