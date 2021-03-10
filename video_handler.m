classdef video_handler
    %VIDEO_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reader = [];
        player = [];
        
        memory = 3;
        old_frame = cell(0);
        frame = [];
        report = [];
        old_report = cell(0);
        
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
            obj.old_report = cell( obj.memory, 1);
        end
        
        function obj = update_old( obj )
            %update old frame for step analysis
            obj.old_frame = [obj.old_frame(1); obj.old_frame(1:2)]; 
            obj.old_frame{1} = obj.frame;
            
            obj.old_report = [obj.old_report(1); obj.old_report(1:2)];
            obj.old_report{1} = obj.report;
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
        
        function infos = prepare_for_recovery( obj )
            frames = cell(4, 1);
            frames{1} = obj.frame; 
            frames(2:end) = obj.old_frame;
            
            reports = cell(4, 1);
            reports{1} = obj.report;
            reports(2:end) = obj.old_report;
            
            infos = struct( 'frames', frames, 'reports', reports);
        end
    end
end

