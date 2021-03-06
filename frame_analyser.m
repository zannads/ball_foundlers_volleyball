classdef frame_analyser
    %FRAME_ANALYSER Class to analyse the frames in a volleyball match
    %   To recognise the ball in a volleyball match is a hard work. To do
    %   so, multiple analysis needs to be performed, using differente
    %   techinques because the ball doesn't have any typical feature that
    %   makes it easy to be recognised.
    %   This techniques includes:
    %   - Mixture of gaussian to learn the background.
    %   - blob analyser system object to recognize the moving objects.
    %   - analysis of subsequent frames to detect fast moving objects.
    %   - hsv space color analysis.

    properties (Access=private)
        % Look at the constructor for more info.
        f_detector = [];
        blob_analyser = [];
        h_tracker = [];
        block_matcher = [];
        template_matcher = [];
        
        report = [];
        debug = 0;
        
        % default Params
        num_gaussians  = 5;
        minimum_back_ratio = 0.7;
        adapt_learning_rate = 0;
        train_frames = 500;
        min_area = 400;
        max_area = 800;
    end
    
    methods
        %% Constructor
        function obj = frame_analyser()
            % Create System objects for foreground detection and blob
            % analysis.
            
            % The foreground detector is used to segment moving objects from
            % the background. It outputs a binary mask, where the pixel value
            % of 1 corresponds to the foreground and the value of 0 corresponds
            % to the background.
            
            if obj.adapt_learning_rate
                obj.f_detector = vision.ForegroundDetector('NumGaussians', obj.num_gaussians, ...
                    'NumTrainingFrames', obj.train_frames, 'MinimumBackgroundRatio', obj.minimum_back_ratio);
            else
                obj.f_detector = vision.ForegroundDetector('NumGaussians', obj.num_gaussians, ...
                    'AdaptLearningRate', obj.adapt_learning_rate, 'MinimumBackgroundRatio', obj.minimum_back_ratio);
            end
            
            % Connected groups of foreground pixels are likely to correspond to moving
            % objects.  The blob analysis System object is used to find such groups
            % (called 'blobs' or 'connected components'), and compute their
            % characteristics, such as area, centroid, and the bounding box.
            
            obj.blob_analyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
                'AreaOutputPort', true, 'CentroidOutputPort', true, ...
                'MinimumBlobArea', obj.min_area, 'MaximumBlobArea', obj.max_area);
            
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
            % the structure of the report is the following one:
            %   - for foreground analysis and step (difference between frames):
            %       - mask: binary image obtained from the techinque.
            %       - c_number: number of found circles.
            %       - c_centers: center of the found circles.
            %       - c_radii: radius of the corresponding circles.
            %       - b_number: number of validated blobs.
            %       - b_centers: center of the validated blobs.
            %       - b_axis: the two major directions of the blobs.
            %   - for hsv space: just the mask obatined.
            t = struct( 'mask', [], 'c_number', 0, 'c_centers', [], 'c_radii', [], 'b_number', 0, 'b_centers', [], 'b_axis', [] );
            
            obj.report = struct( 'foreground', t, 'stepper', t, 'hsv', [] );
        end
        
        %% METHODS
        
        function obj = write_report( obj, frame, old_frame, last_known)
            %WRITE_REPORT Analysis of the frame based on old informations.
            % this method analyses the frame using the 3 techinques
            % introduced above. Then, for each of them it just checks for the
            % most closed circles to the latest known position.
            % It looks only for circles because for most of the time it
            % should be enough.
            
            % Foreground detection
            obj.report.foreground.mask = obj.foreground_analysis( frame);
            % Search round objects in the mask.
            obj = obj.circle_search( 'foreground', last_known );
            
            % Step detecion
            obj.report.stepper.mask = obj.step_analysis( frame, old_frame);
            
            obj = obj.circle_search( 'stepper', last_known );
            
            % Color space detection.
            obj.report.hsv = obj.hsv_analysis( frame );
            % no circle search
        end
        
        function obj = deepen_report( obj )
            %DEEPEN_REPORT Analysis of the frame for blob detection when
            %circle search has failed.
            % This method searches for blobs that can be connected to the
            % ball using the 3 masks already computed.
            
            % to do:
        end
        
        function [set] = foreground_analysis_blobanalyser( obj, frame)
            %FOREGROUND_ANLYSIS_BLOBANALYSER Perform recognition of bboxes
            %using blob analyser.
            
            % Detect foreground.
            set.mask = obj.f_detector.step(frame);
            
            % Apply morphological operations to remove noise and fill in holes.
            set.mask = imopen(set.mask, strel('rectangle', [3,3]));
            set.mask = imclose(set.mask, strel('rectangle', [15, 15]));
            set.mask = imfill(set.mask, 'holes');
            
            % Perform blob analysis to find connected components.
            [~, centroids, bboxes] = obj.blob_analyser.step(set.mask);
            
            % Remove not squared boxes.
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
            
            set.bboxes = bboxes;
            set.centroids = centroids;
        end
        
        function [mask] = foreground_analysis( obj, frame)
            % Detect foreground.
            if obj.adapt_learning_rate
                mask = obj.f_detector.step(frame);
            else
                l_r = 0.000000001; 
                mask = obj.f_detector.step(frame, l_r);
            end
            
            % Apply morphological operations to remove noise and fill in holes.
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
        end
        
        function [mask] = learn_background( obj, frame, l_r ) %#ok<INUSD>
            % Detect foreground.
            if obj.adapt_learning_rate
                mask = obj.f_detector.step(frame);
            else
                %when using AdaptLearningRate == true the learning rate is
                %fixed to 1/number of frame thus, I pass l_r and invert it 
                %l_r = l_r.^(-1);
                l_r = 0.005; 
                mask = obj.f_detector.step(frame, l_r);
            end
        end
        
        function [mask] = hsv_analysis ( obj, frame ) %#ok<INUSL>
            % try to look for yellows
            color = [0.15, 0.25];
            
            hsv_frame = rgb2hsv(frame);
            
            mask = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
            
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            %eventually
            % bbox = obj.h_tracker( hsv_frame(:,:,1) ); %#ok<NASGU>
        end
        
        function [mask] = step_analysis( obj, frame, old_frame ) %#ok<INUSL>
            %analysis between subsequnet frames
            mask = sum( abs( old_frame-frame ), 3 ) > 20;
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            %eventually
            %motion = obj.block_matcher( frame, obj.old_frame ); %#ok<NASGU>
        end
        
        function obj = circle_search( obj, who, last_known  )
            mask = obj.report.(who).mask;
            
            [mask, v_x, v_y] = extract_roi( mask, last_known.position, 100 );
            radius = last_known.radii;
            m_r = min( max( floor(0.5*radius), 3), 10) ;
            M_r = max( min( ceil(1.5*radius), 15), 5);
            [centers, radii] = imfindcircles(mask, [m_r, M_r]);
            
            l = size( centers, 1);
            if l
                obj.report.(who).c_number = l;
                obj.report.(who).c_centers = centers + [v_x, v_y];
                obj.report.(who).c_radii = radii;
            end
        end
        
        function [out] = get_report( obj )
            out = obj.report;
        end
        
        
    end
end

