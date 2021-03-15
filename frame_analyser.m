classdef frame_analyser
    %FRAME_ANALYSER Class to analyse the frames in a volleyball match
    %   To recognise the ball in a volleyball match is a hard work. To do
    %   so, multiple analysis need to be performed using different
    %   techinques. The ball doesn't have any typical feature that
    %   makes it easy to be recognised.
    %   This techniques includes:
    %   - Mixture of gaussian to learn the background.
    %   - Blob analyser system object to recognize the moving objects.
    %   - Analysis of subsequent frames to detect fast moving objects.
    %   - HSV space color analysis.
    
    properties (Access=private)
        % Look at the constructor for more info.
        f_detector = [];            % Foreground detector
        blob_analyser = [];         % Blob analyser
        h_tracker = [];             % Histogram tracker (not used)
        block_matcher = [];         % Block matcher (not used)
        template_matcher = [];      % Template matcher (not used)
        
        report = [];                % Report created
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
            %FRAME_ANALYSER Create System objects analysis.
            
            % The foreground detector is used to segment moving objects from
            % the background. It outputs a binary mask, where the pixel value
            % of 1 corresponds to the foreground and the value of 0 corresponds
            % to the background.
            
            if obj.adapt_learning_rate
                % If adapt learning rate is active the first frames are
                % used to train the object and then it keeps uploading the
                % model.
                obj.f_detector = vision.ForegroundDetector('NumGaussians', obj.num_gaussians, ...
                    'NumTrainingFrames', obj.train_frames, 'MinimumBackgroundRatio', obj.minimum_back_ratio);
            else
                % When this properties is set to zero I can pass to the
                % system object also the learning rate and then make it not
                % learning during tracking.
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
            
            % Histogram based tracking tracks an object following the hsv
            % space of that element. In this case it doens't work because
            % the ball doesn't have a fixed color.
            %             start_image_hsv = rgb2hsv(start_image);
            %             ball_starting_region = [290, 190, 16, 16];
            %             % using hsv tracking I create the object histogram
            %             obj.h_tracker = vision.HistogramBasedTracker;
            %             initializeObject(obj.h_tracker, start_image_hsv(:,:,1) , ball_starting_region);
            %
            
            % Block matcher object find the moving object between two
            % frames. Could have been useful, but ball is too small.
            %             obj.block_matcher = vision.BlockMatcher('ReferenceFrameSource',...
            %                 'Input port','BlockSize',[720 1280]);
            %             obj.block_matcher.OutputValue = 'Horizontal and vertical components in complex form';
            %
            % Template matching can be useful to detect the ball at the
            % beginning. It is really heavy computationally speaking.
            % Unfortunately ball is too far and doesn't have any particular
            % feature.
            %             obj.template_matcher = vision.TemplateMatcher('ROIInputPort', true, ...
            %                 'BestMatchNeighborhoodOutputPort', true);
            %
            % The structure of the report is the following one:
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
            % Erase old report.
            t = struct( 'mask', [], 'c_number', 0, 'c_centers', [], 'c_radii', [], 'b_number', 0, 'b_centers', [], 'b_axis', [] );
            obj.report = struct( 'foreground', t, 'stepper', t, 'hsv', [] );
            
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
        %%
        function obj = deepen_report( obj, last_known )
            %DEEPEN_REPORT Analysis of the frame for blob detection when
            %circles search has failed.
            % This method searches for blobs that can be connected to the
            % ball using the 3 masks already computed.
            
            %obj = obj.blob_search( 'foreground', last_known );
            
            obj = obj.blob_search( 'stepper', last_known );
        end
        
        function [set] = foreground_analysis_blobanalyser( obj, frame)
            %FOREGROUND_ANLYSIS_BLOBANALYSER Perform recognition of bboxes
            %using blob analyser.
            
            % This method hasn't been used anymore.
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
                % if it does it autonomously you pass just the frame.
                mask = obj.f_detector.step(frame);
            else
                % Otherwise also a very small learning rate so that it is
                % not learning.
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
                %in case I want to use the same technique. Otherwise 0.005,
                %the default value is ok. Changing this parameter strongly
                %affect the results and for fast changing scene may not provide
                %stability to the algorithm.
                %l_r = l_r.^(-1);
                l_r = 0.005;
                mask = obj.f_detector.step(frame, l_r);
            end
        end
        
        function [mask] = hsv_analysis ( obj, frame ) %#ok<INUSL>
            %HSV_ANALYSIS Search in the image for yellow
            % try to look for yellows
            color = [0.15, 0.25];
            
            % move to hsv space
            hsv_frame = rgb2hsv(frame);
            
            % Create the mask
            mask = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
            
            % Apply morphological operations to remove noise and fill in holes.
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            %eventually
            % bbox = obj.h_tracker( hsv_frame(:,:,1) ); %#ok<NASGU>
        end
        
        function [mask] = step_analysis( obj, frame, old_frame ) %#ok<INUSL>
            %STEP_ANALYSIS Performs the analysis between two subsequent
            %frames
            
            % take just the pixel where there is a change in color big
            % enough.
            mask = sum( abs( old_frame-frame ), 3 ) > 20;
            
            % Apply morphological operations to remove noise and fill in holes.
            mask = imopen(mask, strel('rectangle', [3,3]));
            mask = imclose(mask, strel('rectangle', [15, 15]));
            mask = imfill(mask, 'holes');
            
            %eventually
            %motion = obj.block_matcher( frame, obj.old_frame ); %#ok<NASGU>
        end
        
        function obj = circle_search( obj, who, last_known  )
            %CIRCLE_SEARCH Searches for circle on the requested mask. 
            
            % get the mask
            mask = obj.report.(who).mask;
            
            % Concentrate on the 200 x 200 square around the last position 
            % Get the reduced mask and the shift of its high-left point
            [mask, v_x, v_y] = extract_roi( mask, last_known.position, 100 );
            
            % Get the actual radius to search for circle of a similar
            % dimension. from m_r to M_r. with a limit [3, 15]
            radius = last_known.radii;
            m_r = min( max( floor(0.5*radius), 3), 10) ;
            M_r = max( min( ceil(1.5*radius), 15), 5);
            
            % find circles
            [centers, radii] = imfindcircles(mask, [m_r, M_r]);
            
            % if at least one circle has been found.
            l = size( centers, 1);
            if l
                % save the number of circles 
                obj.report.(who).c_number = l;
                % shift them on the original coordinates of the big mask.
                obj.report.(who).c_centers = centers + [v_x, v_y];
                obj.report.(who).c_radii = radii;
            end
        end
        
        function obj = blob_search( obj, who, last_known )
            %BLOB_SEARCH Search for blob objects in the request mask. 
            
            % get the mask
            mask = obj.report.(who).mask;
            
            % Concentrate on the 200 x 200 square around the last position 
            % Get the reduced mask and the shift of its high-left point
            [mask, v_x, v_y] = extract_roi( mask, last_known.position, 150 );
            
            % Blob analysis 
            stats = regionprops('struct', mask ,'Area', 'BoundingBox', 'Centroid',...
                'Circularity', 'MajorAxisLength', 'MinorAxisLength', 'Orientation' );
           
            % I have to prune results, based on Area, circularity ecc 
           idx = 1;
            while ~isempty(stats) & idx <= size( stats, 1)
                if ( stats(idx).Area > 600 | stats(idx).Area < 100 | stats(idx).Circularity < 0.3 )
                    % if area is too putside the range 100-600 or
                    % circularity is not enough. false positive.
                    stats(idx) = [];
                else 
                    idx = idx + 1;
                end
            end
            
            % Get the numebr of detection still present.
            l = (size( stats , 1)*( ~isempty(stats) )) > 0;
            if l
                % save the number.
                obj.report.(who).b_number = size( stats , 1);
                % save coordinates and shift them in the original mask
                obj.report.(who).b_centers = extractfield_( stats, 'Centroid') + [v_x, v_y];
                obj.report.(who).b_radii = extractfield_( stats, 'MajorAxisLength')/2;
               
            end
            
        end
        
        function [out] = get_report( obj )
            %GET_REPORT Give back the report.
            out = obj.report;
        end
        
        
    end
end