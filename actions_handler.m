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
            if obj.idx() == obj.lenght_set
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
            if step > obj.lenght_set | step < 1 %#ok<OR2>
                disp( "Invalid number of action." );
                return;
            end
            
            % Set the cursor of the action we want. 
            obj.idx( step );
            
            % Get it with dynamic assignment.
            name = strcat( "action_", num2str( obj.idx() ) );
            action = obj.set.(name);
        end
        
        function detection = get_detection( obj, step )
            %GET_DETECTION Gives back the history tracker of the requested
            %action saved in the object.
            detection = [];
            
            % If number is wrong, nothing is given back.
            if step > obj.lenght_det | step < 1 %#ok<OR2>
                disp( "Invalid number of action." );
                return;
            end
            
            % Get it with dynamic assignment.
            name = strcat( "action_", num2str( step ) );
            detection = obj.det.(name);
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
        
        function out = lenght_set( obj )
            %LENGHT_SET The number of actions saved in the object.
           out = numel( fieldnames( obj.set ) );
        end
        
        function out = lenght_det( obj )
            %LENGHT_DET The number of history trackers saved in the object.
            out = numel( fieldnames( obj.det ) );
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
            
            % get the initial information of time of the service and side
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
                
                % set the net
                real_p = volleyball_pitch;
                ball = ball.set_net( real_p.get_net( obj.get_P) );
                
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
        
        function obj = end_action( obj, ball )
            %END_ACTION Saves the infromations of the tracking.
            % Again, the referee whistle and
            % the action has endeed. 
            
            % I have to understand the second point for the plane where the
            % action take place based on how the ball stopped.
            if ball.get_end == 0
                % time expired
            elseif ball.get_end == 1
                % consecutive invisible! players check
                
            elseif ball.get_end == 2
                % hits the net! fix x = 0
                p = ball.last_known;
                
                p_ = point3d_from_2d( p(1), p(2), obj.get_P, 'x', 0);
                
                ball = ball.set_point( 2, p_);
            end
            
            % now that I have tracked the ball I want to see it in 3d.
            ball = ball_foundlers_convert2dto3d( ball, obj.get_P, obj.get_range );
                
            name = strcat( 'action_', num2str( obj.idx() ) );
            
            % The history tracker is saved
            obj.det.(name) = ball;
            
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