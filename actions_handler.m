classdef actions_handler
    %ACTIONS_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        set = [];
        total = 0;

        training_frames = [1, 800];
    end
    
    properties (Access=private)
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
            
            obj.set = load( fullfile( obj.file_directory, obj.filename ) );
            
            obj.videoname = obj.set.videoname;
            obj.set = rmfield( obj.set, 'videoname' );
            
            obj.training_frames =obj.set.training_frames;
            obj.set = rmfield( obj.set, 'training_frames' );
            
            
            % get obj.total
            obj.total = numel( fieldnames( obj.set ) );
            
            % I'll leave idx and current empty
            % I'll get them using next
            obj.idx( 0 );
            
        end
        
        function action = next(obj )
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            if obj.idx() == obj.total
                disp( "No more actions saved in this match." );
                action = obj.get( obj.idx() );
                return;
            end
            
            action = obj.get( obj.idx() + 1);
        end
        
        function action = get( obj, step )
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
            videoname = obj.videoname; %#ok<PROP>
            training_frames = obj.training_frames; %#ok<PROP>
            set = obj.set; %#ok<PROP>
            save actions.mat videoname training_frames
            
            for jdx = 1:obj.total
                name = strcat( "action_", num2str( jdx ) );
                save( 'actions.mat', '-struct', 'set', name, '-append' );
            end
            
            cd( c_pos );
            e = 0;
        end
        
        function obj = add( obj )
            name = strcat( "action_", num2str( obj.total + 1 ) );
            obj.set.(name) = [] ;
            
            str = input( "Starting time :");
            obj.set.(name).starting_time = str;
            
            reader = VideoReader( obj.videoname );            
            reader.CurrentTime = obj.set.(name).starting_time;
    
            frame = readFrame( reader );
            f_h = figure; imshow( frame ); title( 'Select the starting position of the ball' );
            
            [x, y] = getpts();
            obj.set.(name).position_x = [ floor( min(x)), ceil( max(x) ) ]; 
            obj.set.(name).position_y = [ floor( min(y)), ceil( max(y) ) ]; 
            close(f_h);
            disp( "Thank you :) ");
            % for this moment always right side, in future I can discriminate
            % better
            obj.set.(name).starting_side = 0;
            
            disp(  "Starting side : ");
            disp( obj.set.(name).starting_side );
            disp( " ");
            disp(  "Starting position x : ");
            disp( obj.set.(name).position_x );
            disp( " ");
            disp(  "Starting position y : ");
            disp( obj.set.(name).position_y );
            disp( " ");
            
            str = input( "Ending time : ");
            obj.set.(name).ending_time = str;
            
            obj.total = obj.total +1;
        end
        
        function obj = set_videoname( obj, path_ )
            obj.videoname = path_;
        end
        
        function out = get_videoname( obj )
            out = obj.videoname;
        end
       
        function ball = start_action( obj )
            % when the referee whistle the action begins
            % Iìd like to use the template matcher, to find the first
            % instance of the ball.
            % now I just select it
           current = obj.get( obj.idx() );
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
        
        function out = end_action( obj, ball )
            %again, the referee whistle, ball has touched the ground. ended
            %action
            name = strcat( 'detected_action_', num2str( obj.idx() ), '.mat' );
            
            frame = cell( ball.length, 1);
            position = cell( ball.length, 1);
            
            for idx = 1:ball.length
                frame{idx} = idx;
                
                if strcmp( ball.state{idx}, 'unknown' )
                    position{idx} = [];
                else
                    position{idx} = ball.image_coordinate{idx};
                end
            end
            
            save(  name, 'frame', 'position');
                
            out = [];
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

