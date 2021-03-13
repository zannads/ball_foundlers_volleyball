classdef actions_handler
    %ACTIONS_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        set = [];
        det = [];
        total = 0;
    end
    
    properties (Access=private)
        P = [];
        camera_position = [];
        camera_rotation = [];
        camera_parameters = [];
        
        training_frames = [];
        
        file_directory = [];
        filename = [];
        
        videoname = [];
    end
    
    methods
        function obj = actions_handler(file_directory, filename)
            %ACTIONS_HANDLER Construct an instance of this class
            %   Detailed explanation goes here
            obj.file_directory = file_directory;
            obj.filename = filename;
            
            if exist( fullfile( obj.file_directory, obj.filename ), 'file' )
                loader = load( fullfile( obj.file_directory, obj.filename ) );
                obj = loader.obj;
            end
            
            % I'll leave idx and current empty
            % I'll get them using next
            obj.idx( 0 );
        end
        
        function action = next(obj )
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            if obj.idx() == obj.total
                disp( "No more actions saved in this match." );
                action = obj.get_action( obj.idx() );
                return;
            end
            
            action = obj.get_action( obj.idx() + 1);
        end
        
        function action = get_action( obj, step )
            action = [];
            
            if step > obj.total | step < 1
                disp( "Invalid number of action." );
                return;
            end
            
            obj.idx( step );
            
            name = strcat( "action_", num2str( obj.idx() ) );
            action = obj.set.(name);
        end
        
        function e = save_all( obj )
            c_pos = cd;
            cd( obj.file_directory );
%           
            save( obj.filename, 'obj' );

            cd( c_pos );
            e = 0;
        end
        
        function obj = set_videoname( obj, path_ )
            obj.videoname = path_;
        end
        
        function out = get_videoname( obj )
            out = obj.videoname;
        end
        
        function obj = set_training_frames( obj, range )
            obj.training_frames = range;
        end
        
        function range = get_training_frames( obj )
            range = obj.training_frames;
        end
        
        function obj = set_P( obj, P )
            obj.P = P;
        end
        
        function P = get_P ( obj )
            P = obj.P;
        end
        
        function obj = set_camera_position( obj, camera_position )
            obj.camera_position = camera_position;
        end
        
        function camera_position = get_camera_position( obj ) 
            camera_position = obj.camera_position;
        end
        
        function obj = set_camera_rotation( obj, camera_rotation )
            obj.camera_rotation = camera_rotation;
        end
        
        function camera_rotation = get_camera_rotation( obj ) 
            camera_rotation = obj.camera_rotation;
        end
        
         function obj = set_camera_parameters( obj, camera_parameters )
            obj.camera_parameters = camera_parameters;
        end
        
        function camera_parameters = get_camera_parameters( obj ) 
            camera_parameters = obj.camera_parameters;
        end
        
        
        function range3d = get_range( obj ) 
           if isempty( obj.camera_position )
               range3d = [-9, 9, 0, 9, 0, 5];
           else
               c_x = obj.camera_position(1);
               c_y = obj.camera_position(2);
               
               range3d = [min( -9, c_x), max(9, c_x), min(0, c_y), max(9, c_y), 0, 5];
           end
        end
        
        function ball = start_action( obj )
            % when the referee whistle the action begins
            % Iìd like to use the template matcher, to find the first
            % instance of the ball.
            % now I just select it
            current = obj.get_action( obj.idx() );
            x = current.position_x;
            y = current.position_y;
            
            ball = history_tracker();
            ball.starting_side = current.starting_side;
            
            if( ball.starting_side == 0 ) % it's on the far side
                %it should be visible
                
                ball.bbox{end} = [x(1), y(1), (x(2)-x(1)), (y(2)-y(1))];
                ball.radii{end} = mean( [(x(2)-x(1)), (y(2)-y(1))])/2;
                ball.image_coordinate{end} = [ ((x(1)+x(2))/2),  ((y(1)+y(2))/2)];
                ball.state{end} = "known";
                ball.length = 1;
                ball.total_visible_count = 1;
                ball.consecutive_invisible = 0;
                
                
            else
                % it's out of the picture or covered
                
            end
        end
        
        function [out, obj] = end_action( obj, ball )
            %again, the referee whistle, ball has touched the ground. ended
            %action
            name = strcat( 'action_', num2str( obj.idx() ) );
            
            obj.det.(name).frame = cell( ball.length, 1);
            obj.det.(name).position = cell( ball.length, 1);
            
            reader = VideoReader( obj.videoname );
            
            for idx = 1:ball.length
                obj.det.(name).frame{idx} = obj.set.(name).starting_time + (idx-1)/reader.FrameRate;
                
                if strcmp( ball.state{idx}, 'unknown' )
                    obj.det.(name).position{idx} = [];
                else
                    obj.det.(name).position{idx} = ball.image_coordinate{idx};
                end
            end
          
          out = [];
        end
        
        function out = get_complete_action( obj )
            out.P = obj.P;
            out.R = obj.camera_rotation;
            out.O = obj.camera_position;
            out.range = obj.get_range();
            
            name = strcat( 'action_', num2str( obj.idx ) );
            out.manual = obj.set.(name);
            out.detected = obj.det.(name);
        end
        
        function obj = add( obj, varargin )
            if nargin > 1 
                num = varargin{1};
            else 
                num = obj.total + 1;
            end
               
            name = strcat( "action_", num2str( num ) );
            obj.set.(name) = [] ;
            
            reader = VideoReader( obj.videoname );
            
            %%%%%%%%%%%%% JUMP INFO
            %%%%% START OF THE JUMP 
            str = input( "Insert approximate starting time of the jump:");
            reader.CurrentTime = str;
            while str
                % go to next frame
                frame = readFrame( reader );
                if exist( 'f_h', 'var' )
                    close(f_h);
                end
                f_h = figure; imshow( frame );
                % ask if is landing, if yes acquire point
                str = input( 'Is the jump? Answer how many steps forward/backward you want to go: ' );
                if str ~= 0
                    %jump forward (one step has already been done in
                    %readFrame
                    reader.CurrentTime = reader.CurrentTime + (str-1)/reader.FrameRate;
                end
            end
            
            % I need 1 point from the start of the jump
            ball_foundlers_save_manual_clicked( 'reset' );
            ball_foundlers_save_manual_clicked( 'set', 1 );
            
            % show the image
            title( 'Select the starting point of the jump' );
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
            % save the staring point of the jump and the number of frame
            % from starting point
            obj.set.(name).jump_s_pos = ball_foundlers_save_manual_clicked( 'is_acquired' );
            obj.set.(name).jump_s_time = reader.CurrentTime - 1/reader.FrameRate;
            
            %%%%% END OF THE JUMP 
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
                str = input( 'Is the landing? Answer how many steps forward/backward you want to go ' );
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
            
            % save the staring point of the jump and the number of
            % frame from starting_time
            obj.set.(name).jump_e_pos  = ball_foundlers_save_manual_clicked( 'is_acquired' );
            obj.set.(name).jump_e_time = reader.CurrentTime - 1/reader.FrameRate;
            
            
            %%%%% BALL USEFUL START
            % The useful trajectory of the ball is between jump_st.rel_frame and  jump_end.rel_frame
            
            reader.CurrentTime = (obj.set.(name).jump_e_time+obj.set.(name).jump_s_time)/2;
            obj.set.(name).ball_s_time = reader.CurrentTime;
            
            
            %%%%%%%%%%%%% RECEIVED BALL
            %%%%% START OF THE "JUMP" 
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
                    %readFrame
                    reader.CurrentTime = reader.CurrentTime + (str-1)/reader.FrameRate;
                end
            end
            
            % now I'm when the ball is received.
            % I don't need the position, just the time to end the loop in
            % the main program
            obj.set.(name).ball_e_time = reader.CurrentTime - 1/reader.FrameRate;
            
            % asj how the action ends:
            disp( 'How does the action ends?');
            disp( '1 On the net. ');
            disp( '2 On the floor. ');
            disp( '3 On the hands of a player. ');
            str = input( 'Insert the answer: ');
            
            if str == 1
                obj.set.(name).ball_e_mode = 1;
                % Ends on the net, thus I will have the point when it
                %touches the net that is above the nezt one.
                
                obj.set.(name).rec_s_pos  = [];
                obj.set.(name).rec_s_time = obj.set.(name).ball_e_time;
                obj.set.(name).rec_e_pos  = [];
                obj.set.(name).rec_e_time = obj.set.(name).ball_e_time;
            elseif str == 2
                obj.set.(name).ball_e_mode = 2;
                % Ends on the floor, thus its height is the radius of a
                % ball in the real world.
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
                
                % frame after
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
            
            %%%%%%%%%%%DETECTION PARAMS 
            % START
            str = input( "Insert approximate starting time of the detection:");
            reader.CurrentTime = str;
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
            
            %END
            str = input( "Insert ending time of detection:");
            obj.set.(name).ending_time = str;
            
            close(f_h) ;
            clc;
            disp( "Thank you :) ");
            obj.total = obj.total +1;
        end
        
        function obj = replace( obj, number )
            name = strcat( 'action_', num2str( number ) );
            obj.set.(name) = [];
            obj.total = obj.total -1;
            
            obj = obj.add( number );
        end
        
    end
    
    methods (Static)
        function out = idx( data )
            persistent idx_ ;
            if nargin
                idx_ = data;
            end
            out = idx_;
        end
    end
end

