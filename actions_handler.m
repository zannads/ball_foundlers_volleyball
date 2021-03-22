classdef actions_handler
    %ACTIONS_HANDLER Class to manage the file of the volleyball match and 
    %the services inside that video. 
    %   This class loads and keeps the name of the video to use it when it
    %   is needed. 
    %   Furthermore, it offers the possibility to keep the information
    %   gained during the calibration process. 
    %   The main part is the store of the services and of its detection. 
    %   Everything can be saved for further upload. 
    %   How services are defined: 
    %       - some important informations regarding time in the video of it. 
    %       - starting position and infos about the jump of the player.
    %       - informations about the end of the service.
    %   How detection are saved:
    %       - time of the frame.
    %       - position of the center of the ball.
    
    properties
        set = [];   % Struct to save services informations. 
        det = [];   % Struct to save ball detections.
        total = 0;  % NUmber of actions in set. 
    end
    
    properties (Access=private)
        P = [];                     % Projection Matrix of the camera.
        camera_position = [];       % Position of the camera with respect to the reference fixed in the pitch.
        camera_rotation = [];       % Rotation of the camera with respect to the reference fixed in the pitch.
        camera_parameters = [];     % Calibration Matrix of the camera.
        
        training_frames = [];       % Set of frames to be used to calibrate the foreground detector.
        
        file_directory = [];        % Directory where to save/upload this object.
        filename = [];              % Name to save/upload this object.
        
        videoname = [];             % Path where to find the video to analyse.
    end
    
    methods
        function obj = actions_handler(file_directory, filename)
            %ACTIONS_HANDLER Construct an instance of this class.
            %   During the creation of the class it tries to upload the
            %   file. If it is not found an empty class is generated.
            %   Name and directory needs to be passed anyway because they
            %   allow the saving of a new object eventually.
            obj.file_directory = file_directory;
            obj.filename = filename;
            
            if exist( fullfile( obj.file_directory, obj.filename ), 'file' )
                loader = load( fullfile( obj.file_directory, obj.filename ) );
                obj = loader.obj;
            end
            
            % Current idx of the anlaysis process. Zero because anything
            % hasn't started yet.
            obj.idx( 0 );
        end
        %%
        function action = next(obj )
            %NEXT Gives back the information of the next action saved in
            %the object .
            %   This function can be used to automatize the process since
            %   it keeps in its memory which actions have already been
            %   given back.
            
            % If we are at the end, do nothing.
            if obj.idx() == obj.total
                disp( "No more actions saved in this match." );
                return;
            end
            
            % Get the desired action and give that back. 
            action = obj.get_action( obj.idx() + 1);
        end
        
        function action = get_action( obj, step )
            %GET_ACTION Gives back the information of the requested action
            %saved in the object.
            action = [];
            
            % If number is wrong, nothing is given back.
            if step > obj.total | step < 1 %#ok<OR2>
                disp( "Invalid number of action." );
                return;
            end
            
            % Set the cursor of the action we want. 
            obj.idx( step );
            
            % Get it with dynamic assignment.
            name = strcat( "action_", num2str( obj.idx() ) );
            action = obj.set.(name);
        end
        
        function e = save_all( obj )
            %SAVE_ALL Save the object on the requested directory. 
            % The program may be running on a different folder than where we
            % want to save it. The function handles this problem.
            
            % Save current position of the directory.
            c_pos = cd;
            
            % Move where we want to save.
            cd( obj.file_directory );
            
            % Self explainatory.
            save( obj.filename, 'obj' );

            % Go back to it 
            cd( c_pos );
            
            % Arrangement to rethrow errors. Not implement yet.
            e = 0;
        end
        
        function obj = set_videoname( obj, path_ )
            %SET_VIDEONAME Set the name of the video. 
            % The name needs to include the whole path. 
            obj.videoname = path_;
        end
        
        function out = get_videoname( obj )
            % GET_VIDEONAME Get the name of the video.
            out = obj.videoname;
        end
        
        function obj = set_training_frames( obj, range )
            %SET_TRAINING_FRAMES Set the interval of training frames of the
            %video.
            % The properties needs to be defined in the following way. The
            % number of the frame from the beginning of the video, to the
            % number of the end of this process. 
            % Thus, the number of frame used to train is get as
            % training_frames(2) - training_frames(1)
            obj.training_frames = range;
        end
        
        function range = get_training_frames( obj )
            %GET_TRAINING_FRAMES Get the interval of the training frames of
            %the video. 
            range = obj.training_frames;
        end
        
        function obj = set_P( obj, P )
            %SET_P Set the projection matrix of the camera used in this
            %video. 
            obj.P = P;
        end
        
        function P = get_P ( obj )
            % GET_P Get the projection matrix of the camera used in this
            %video. 
            P = obj.P;
        end
        
        function obj = set_camera_position( obj, camera_position )
            %SET_CAMERA_POSITION Set the camera position coordinates of the
            %camera used in this video with respect to the volleyball
            %pitch.
            obj.camera_position = camera_position;
        end
        
        function camera_position = get_camera_position( obj ) 
            %GET_CAMERA_POSITION Get the camera position coordinates of the
            %camera used in this video with respect to the volleyball
            %pitch. 
            camera_position = obj.camera_position;
        end
        
        function obj = set_camera_rotation( obj, camera_rotation )
            %SET_CAMERA_ROTATION Set the camera rotation matrix of the
            %camera used in this video with respect to the volleyball
            %pitch.
            obj.camera_rotation = camera_rotation;
        end
        
        function camera_rotation = get_camera_rotation( obj ) 
            %GET_CAMERA_ROTATION Get the camera rotation matrix of the
            %camera used in this video with respect to the volleyball
            %pitch.
            camera_rotation = obj.camera_rotation;
        end
        
         function obj = set_camera_parameters( obj, camera_parameters )
            %SET_CAMERA_PARAMETERS Set the camera parameters matrix of the
            %camera used in this video.
            obj.camera_parameters = camera_parameters;
        end
        
        function camera_parameters = get_camera_parameters( obj ) 
            %GET_CAMERA_PARAMETERS Get the camera parameters matrix of the
            %camera used in this video.
            camera_parameters = obj.camera_parameters;
        end
        
        %%
        function range3d = get_range( obj ) 
           %GET_RANGE Builds an array used to project the quadrics in the
           %3dplot.
           
           if isempty( obj.camera_position )
               %If a camera is not present, we restrict the plot to the
               %only pitch.
               range3d = [-9, 9, 0, 9, 0, 5];
           else
               % When also a camera is present, then x and y cooridnates
               % are extended up to that point. In this way it becomes
               % possible to see the full cone.
               c_x = obj.camera_position(1);
               c_y = obj.camera_position(2);
               
               %The range on x and y will go from the camera to the
               %opposite ened of the pitch. On z axis instead we stick to 0
               %to 5 meters. Height that is enough in a gym.
               range3d = [min( -9, c_x), max(9, c_x), min(0, c_y), max(9, c_y), 0, 5];
           end
        end
        
        function ball = start_action( obj )
            %START_ACTION Creates the object to start the detection. 
            % When the referee whistle the action begins, an analysis of
            % the sound of the video should be used to detect this moment.
            
            % get the initial infomration of time of the service and side
            current = obj.get_action( obj.idx() );
            
            % Create the object to keep the informations during the track.
            ball = history_tracker();
            % Save the side. 
            % With this setup this information is useless. But, in case the
            % services are acquired from both the sides this information
            % can be used for an initial guess on the direction of the
            % ball. 
            ball.starting_side = current.starting_side;
            
            if( ball.starting_side == 0 ) % It's on the far side
                pitch_side = [730, 1, 549, 240];
                % get the jump
                [p1, st_time] = ball_foundlers_jump_detector( obj, ...
                    current.starting_time, pitch_side);
                
                % set them
                ball = ball.set_point( 1, p1);
                ball = ball.set_starttime( st_time );
                
                % look for the ball now
                reader = VideoReader( obj.videoname );
                reader.CurrentTime = st_time;
                
                % POSITION
                frame = readFrame( reader );
                f_h = figure; imshow( frame );
                title( 'Select the starting position of the ball' );
                
                [x, y] = getpts();
                x = x(1:2);
                y = y(1:2);
                close(f_h);
                
                % Save information of first position. 
                ball.bbox{end} = [x(1), y(1), (x(2)-x(1)), (y(2)-y(1))];
                ball.radii{end} = mean( [(x(2)-x(1)), (y(2)-y(1))])/2;
                ball.image_coordinate{end} = [ ((x(1)+x(2))/2),  ((y(1)+y(2))/2)];
                ball.state{end} = "known";
                
                ball.total_visible_count = 1;
                ball.consecutive_invisible = 0;
            else
                % Further development needed.
            end
        end
        
        function [out, obj] = end_action( obj, ball )
            %END_ACTION Saves the infromations of the tracking.
            % Again, the referee whistle, ball has touched the ground and
            % the action has endeed. 
            % With this setup is not possible to acquire this information,
            % that is, again, saved in the struct of the action_*.
            name = strcat( 'action_', num2str( obj.idx() ) );
            
            % Time and detection are saved. The cell structure is used
            % because it allows to save empty arrays in case detection
            % hasn't worked in some frame.
            obj.det.(name).frame = cell( ball.length, 1);
            obj.det.(name).position = cell( ball.length, 1);
            
            % I load the video again to avoid the saving of useless
            % informations. It is slower but this operations are not done
            % real time, thus I don't care of performance.
            reader = VideoReader( obj.videoname );
            
            for idx = 1:ball.length
                % Save the time.
                obj.det.(name).frame{idx} = obj.set.(name).starting_time + (idx-1)/reader.FrameRate;
               
                if strcmp( ball.state{idx}, 'unknown' )
                    % If the ball hasn't been detected save empty array.
                    obj.det.(name).position{idx} = [];
                else
                    % else save the center of the ball.
                    obj.det.(name).position{idx} = ball.image_coordinate{idx};
                end
            end
          
          out = [];
        end
        
        function out = get_complete_action( obj )
            %GET_COMPLETE_ACTION Format the useful informations after the
            % tracking for plotting. 
            
            % Infos for nice plots with the camera.
            out.P = obj.P;
            out.R = obj.camera_rotation;
            out.O = obj.camera_position;
            out.range = obj.get_range();
            
            % Detections.
            name = strcat( 'action_', num2str( obj.idx ) );
            out.manual = obj.set.(name);
            out.detected = obj.det.(name);
        end
        
        function obj = add( obj, varargin )
            %ADD This method save the information of a new action.
            % How actions are defined: 
            %   To understand the plane under which the trajectory takes
            %   place we need two points along the trajectory. The third
            %   constraint is the fact that this plane is vertical. Thus we
            %   need the 3d coordinates of two points.
            %   First point:
            %       - Position of the foot on the floor before jump.
            %       - Position of the foot on the floor after the jump. 
            %       - Service starts between this two moments, the x-y
            %       coordinates are found with the two points on the floor
            %       (z = 0).
            %   Second point:
            %       - If the ball ends on the net, we know the x coordinate
            %       is zero because it's the middle of the pitch. 
            %       - If the ball ends on the ground, we know the z
            %       coordinate is zero, because is on the floor.
            %       - If the player hits the ball I get x-y coordinate of
            %       the ball using the foots again.
            % 
            %   To track the ball we need this informations: 
            %       - First detection of the ball is done manually. 
            %       - Time of this detection
            %       - Time when to end tracking.
            
            
            if nargin > 1 
                % If I fix the number, use that.
                num = varargin{1};
            else 
                % Otherwise add to the end. 
                num = obj.total + 1;
            end
               
            % Create the name to use dynamic assignment of the fields of
            % the struct.
            name = strcat( "action_", num2str( num ) );
            obj.set.(name) = [] ;
            
            % read the video and use it for the process.
            reader = VideoReader( obj.videoname );
            
            %%
            % JUMP INFO
            %%%%% START OF THE JUMP 
            str = input( "Insert approximate starting time of the jump:");
            % go to that time.
            reader.CurrentTime = str;
            while str
                % go to next frame
                frame = readFrame( reader );
                if exist( 'f_h', 'var' )
                    close(f_h);
                end
                f_h = figure; imshow( frame );
                % ask if is landing, if 0 then you can acquire point
                str = input( 'Is the jump? Answer how many steps forward/backward you want to go: ' );
                if str ~= 0
                    %jump forward (one step has already been done in
                    %readFrame)
                    reader.CurrentTime = reader.CurrentTime + (str-1)/reader.FrameRate;
                end
            end
           
            % this function saves the clicked points. 
            ball_foundlers_save_manual_clicked( 'reset' );
            % I need 1 point from the start of the jump 
            ball_foundlers_save_manual_clicked( 'set', 1 );
            
            % show the image
            title( 'Select the starting point of the jump' );
            p = detectHarrisFeatures(rgb2gray(frame));
            hold on;
            % let select the point
            for idx = 1:p.Count
                point = p(idx).Location;
                % plot it and add the callback. The callback then will save
                % on ball_foundlers_save_manual_clicked
                plot(point(1), point(2), '*g', 'ButtonDownFcn', @point_select_callback );
            end
            figure( f_h );
            
            %wait until is selected
            pause;
            % save the starting point of the jump and the time.
            obj.set.(name).jump_s_pos = ball_foundlers_save_manual_clicked( 'is_acquired' );
            obj.set.(name).jump_s_time = reader.CurrentTime - 1/reader.FrameRate;
            
            %%
            % END OF THE JUMP 
            % next frame to find the landing
            str = 1;
            
            while str
                % go to next frame
                frame = readFrame( reader );
                if exist( 'f_h', 'var' )
                    close(f_h);
                end
                f_h = figure; imshow( frame );
                % ask if is landing, if yes acquire point
                str = input( 'Is the landing? Answer how many steps forward/backward you want to go: ' );
                if str ~= 0
                    %jump forward (one step has already been done in
                    %readFrame)
                    reader.CurrentTime = reader.CurrentTime + (str-1)/reader.FrameRate;
                end
            end
            
             % I need another 1 point
            ball_foundlers_save_manual_clicked( 'reset' );
            ball_foundlers_save_manual_clicked( 'set', 1 );
            
            title( 'Select the ending point of the jump' );
            p = detectHarrisFeatures(rgb2gray(frame));
            hold on;
            % let select the point
            for idx = 1:p.Count
                point = p(idx).Location;
                plot(point(1), point(2), '*g', 'ButtonDownFcn', @point_select_callback );
            end
            figure( f_h );
            
            %wait until is selected
            pause;
            
            % save the landing point of the jump and the time
            obj.set.(name).jump_e_pos  = ball_foundlers_save_manual_clicked( 'is_acquired' );
            obj.set.(name).jump_e_time = reader.CurrentTime - 1/reader.FrameRate;
            
            %%
            % BALL USEFUL START
            % The useful trajectory of the ball is between jump_st.rel_frame and  jump_end.rel_frame
            
            reader.CurrentTime = (obj.set.(name).jump_e_time+obj.set.(name).jump_s_time)/2;
            obj.set.(name).ball_s_time = reader.CurrentTime;
            
            %%
            % RECEIVED BALL
            str = input( "Insert approximate starting time for the recpetion:");
            reader.CurrentTime = str;
            while str
                % go to next frame
                frame = readFrame( reader );
                if exist( 'f_h', 'var' )
                    close(f_h);
                end
                f_h = figure; imshow( frame ); 
                
                str = input( 'Has the ball been received? Answer how many steps forward/backward you want to go ' );
                if str ~= 0
                    %jump forward (one step has already been done in
                    %readFrame)
                    reader.CurrentTime = reader.CurrentTime + (str-1)/reader.FrameRate;
                end
            end
            
            % now I'm when the ball is received.
            % I don't need the position, just the time to end the loop in
            % the main program.
            obj.set.(name).ball_e_time = reader.CurrentTime - 1/reader.FrameRate;
            
            % ask how the action ends:
            disp( 'How does the action ends?');
            disp( '1 On the net. ');
            disp( '2 On the floor. ');
            disp( '3 On the hands of a player. ');
            str = input( 'Insert the answer: ');
            
            if str == 1
                obj.set.(name).ball_e_mode = 1;
                % Ends on the net, thus I will have the point coordinate x
                % = 0
                obj.set.(name).rec_s_pos  = [];
                obj.set.(name).rec_s_time = obj.set.(name).ball_e_time;
                obj.set.(name).rec_e_pos  = [];
                obj.set.(name).rec_e_time = obj.set.(name).ball_e_time;
                
            elseif str == 2
                obj.set.(name).ball_e_mode = 2;
                % Ends on the floor, thus its height is the radius of a
                % ball in the real world. (Approximated to 0)
                obj.set.(name).rec_s_pos  = [];
                obj.set.(name).rec_s_time = obj.set.(name).ball_e_time;
                obj.set.(name).rec_e_pos  = [];
                obj.set.(name).rec_e_time = obj.set.(name).ball_e_time;
                
            else
                obj.set.(name).ball_e_mode = 3;
                % Ends on the hand of a player receiving the ball,
                % interpolate like in the start.
                
                % now let's triangulate with subsequent frame and the
                % previous one. 
                
                % I need another 1 point
                ball_foundlers_save_manual_clicked( 'reset' );
                ball_foundlers_save_manual_clicked( 'set', 1 );
                
                % frame after the reception.
                frame = readFrame( reader );
                close(f_h);
                f_h = figure; imshow( frame );
                
                title( 'Select ending point of reception');
                p = detectHarrisFeatures(rgb2gray(frame));
                hold on;
                % let select the point
                for idx = 1:p.Count
                    point = p(idx).Location;
                    plot(point(1), point(2), '*g', 'ButtonDownFcn', @point_select_callback );
                end
                figure( f_h );
                
                %wait until is selected
                pause;
                
                obj.set.(name).rec_e_pos  = ball_foundlers_save_manual_clicked( 'is_acquired' );
                obj.set.(name).rec_e_time = reader.CurrentTime - 1/reader.FrameRate;
                
                % Frame before the reception.
                % Let's go two frames before, plus one for the last reading
                reader.CurrentTime = reader.CurrentTime - 3/reader.FrameRate;
                frame = readFrame( reader );
                close(f_h);
                f_h = figure; imshow( frame );
                
                % I need another 1 point
                ball_foundlers_save_manual_clicked( 'reset' );
                ball_foundlers_save_manual_clicked( 'set', 1 );
                
                title( 'Select starting point of reception');
                p = detectHarrisFeatures(rgb2gray(frame));
                hold on;
                % let select the point
                for idx = 1:p.Count
                    point = p(idx).Location;
                    plot(point(1), point(2), '*g', 'ButtonDownFcn', @point_select_callback );
                end
                figure( f_h );
                
                %wait until is selected
                pause;
                
                
                obj.set.(name).rec_s_pos  = ball_foundlers_save_manual_clicked( 'is_acquired' );
                obj.set.(name).rec_s_time = reader.CurrentTime - 1/reader.FrameRate;
            end
            
            %%
            % TRACKING  PARAMS 
            % START 
            % TIME
            str = input( "Insert approximate starting time of the detection:");
            reader.CurrentTime = str;
            
            % POSITION
            frame = readFrame( reader );
            close(f_h);
            f_h = figure; imshow( frame );
            title( 'Select the starting position of the ball' );
            
            [x, y] = getpts();
            x = x(1:2);
            y = y(1:2);
            % for this moment always right side, in future I can discriminate
            % better
            obj.set.(name).starting_side = 0;
            
            obj.set.(name).position_x = [ floor( min(x)), ceil( max(x) ) ];
            obj.set.(name).position_y = [ floor( min(y)), ceil( max(y) ) ];
            obj.set.(name).starting_time = str;
            
            % END
            % TIME
            str = input( "Insert ending time of detection:");
            obj.set.(name).ending_time = str;
            
            close(f_h) ;
            clc;
            disp( "Thank you :) ");
            obj.total = obj.total +1;
        end
        
        function obj = replace( obj, number )
            %REPLACE Replace one action with a new one. 
            % Useful if you save some errors in an action.
            
            name = strcat( 'action_', num2str( number ) );
            %Delete it.
            obj.set.(name) = [];
            obj.total = obj.total -1;
            
            %Create the new one.
            obj = obj.add( number );
        end
        
    end
    
    methods (Static)
        % Since properites cannot be static we need this trick of creating
        % static methods with persisten variables to make varaibels static.
        function out = idx( data )
            persistent idx_ ;
            if nargin
                idx_ = data;
            end
            out = idx_;
        end
    end
end