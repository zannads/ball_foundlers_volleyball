classdef video_handler
    %VIDEO_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reader = [];
        player = [];
        
        memory = 3;
        old_frame = cell(0);
        frame = [];
        
        debug = 0;
    end
    
    methods
        function obj = video_handler(video_directory)
            % Initialize Video I/O
            % Create objects for reading a video from a file, drawing the tracked
            % objects in each frame, and playing the video.
            obj.reader = VideoReader( video_directory );
            
            %   obj.reader.CurrentTime = 180;
            % Create two video players, one to display the video,
            % and one to display the foreground mask.
            % obj.mask_player = vision.VideoPlayer('Position', [740, 400, 700, 400]);
            obj.player = vision.VideoPlayer('Position', [20, 400, 720, 1280]);
            
            obj.old_frame = cell( obj.memory, 1 );
        end
        
        function obj = update_old( obj )
            %update old frame for step analysis
            obj.old_frame = [obj.old_frame(1); obj.old_frame(1:2)]; 
            obj.old_frame{1} = obj.frame;
        end
        
        function ball = start_action( ~ , starting_side,  x, y)
            % when the referee whistle the action begins
            % Iìd like to use the template matcher, to find the first
            % instance of the ball.
            % now I just select it
           
            ball = history_tracker();
            ball.starting_side = starting_side;
            
            if( ball.starting_side == 0 ) % it's on the far side
                %it should be visible
                
                % known info for now it is okay
                %                 x = [839, 853];
                %                 y = [29, 43];
                
                ball.bbox{end} = [x(1), y(1), (x(2)-x(1)), (y(2)-y(1))];
                ball.radii{end} = mean( [(x(2)-x(1)), (y(2)-y(1))])/2;
                ball.image_coordinate{end} = [ ((x(1)+x(2))/2),  ((y(1)+y(2))/2)];
                ball.state{end} = "known";
                ball.length = 1;
                ball.total_visible_count = 1;
                ball.consecutive_invisible = 0;
                
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
            % save and release and display
            %basically release the object ball that tracks history
            %obj.ball = [];
            %save it
        end
        
        function obj = display_tracking( obj, ball, varargin )
            if( ~isempty( ball ) & ~isempty( ball.bbox{end} ) )
                tframe = insertObjectAnnotation(obj.frame, 'rectangle', ...
                    ball.bbox{end}, ball.state{end});
                
                if obj.debug & nargin > 2
                    f_prop = varargin{1};
                    s_prop = varargin{2};
                    if s_prop.length > 0
                    tframe = insertObjectAnnotation(tframe, 'circle', ...
                        [cell2mat(s_prop.centers), cell2mat(s_prop.radii)], "s", 'Color', 'red');
                    end
                    if f_prop.length > 0
                    tframe = insertObjectAnnotation(tframe, 'circle', ...
                        [cell2mat(f_prop.centers), cell2mat(f_prop.radii)], "f", 'Color', 'green');
                    end
                    
                end
                % Draw the objects on the mask.
                %                 mask = insertObjectAnnotation(mask, 'rectangle', ...
                %                     bboxes, label);
            end
            % Display the mask and the frame.
            %obj.mask_player.step(mask);
            obj.player.step(tframe);
        end
        
        function obj = next_frame( obj )
            obj = obj.update_old();
            
            obj.frame = readFrame( obj.reader );
            
        end
        % assign missing
    end
end

