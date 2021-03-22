classdef video_handler
    %VIDEO_HANDLER Class to handle video reader and player. Plus it keeps
    %some memory for fast recovery of the informations.
    %   Detailed explanation goes here
    
    properties
        reader = [];    % Video reader.
        player = [];    % Video player.
        
        % The memory of the system has been included in case the ball was to
        % recover after being lost to avoid to recompute everything since
        % it is the most computational heavy part. 
        memory = 3;             % Memory of the system.
        old_frame = cell(0);    % Memory of the frames. 
        frame = [];             % Current frame.
        report = [];            % Current report. 
        old_report = cell(0);   % Memory of the reports.
    end
    
    methods
        function obj = video_handler(video_directory)
            %VIDEO_HANDLER Allocate the space for the properites and setup
            %the objects.
            
            % Initialize Video reader.
            obj.reader = VideoReader( video_directory );
           
            % Initialize the video player.
            obj.player = vision.VideoPlayer('Position', [20, 400, 1280, 720]);
            
            % Initialize the memory. 
            obj.old_frame = cell( obj.memory, 1 );
            obj.old_report = cell( obj.memory, 1);
        end
        
        function obj = update_old( obj )
            %UPDATE_OLD Save old frames and reports in memories.
            obj.old_frame = [obj.old_frame(1); obj.old_frame(1:2)]; 
            obj.old_frame{1} = obj.frame;
            
            obj.old_report = [obj.old_report(1); obj.old_report(1:2)];
            obj.old_report{1} = obj.report;
        end
        
        
        function obj = display_tracking( obj, ball, varargin )
            %DISPLAY_TRACKING Display the video with the ball position. 
            
            if( ~isempty( ball ) && ~isempty( ball.bbox{end} ) )
                % Contour of the ball. 
                tframe = insertObjectAnnotation(obj.frame, 'rectangle', ...
                    ball.bbox{end}, ball.state{end});
            end
            
            % Display the frame
            obj.player.step(tframe);
        end
        
        function obj = next_frame( obj )
            %NEXT_FRAME Gets the next frame and save the old one.
            obj = obj.update_old();
            
            obj.frame = readFrame( obj.reader );
        end
        
        function infos = prepare_for_recovery( obj )
            %PREPARE_FOR_RECOVERY Thi method format the memory of the
            %object for recovery in case the ball is lost. This
            %informations have to be used outside.
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

