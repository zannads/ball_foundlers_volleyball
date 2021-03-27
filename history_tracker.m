classdef history_tracker
    %HISTORY-TRACKER Class that stores and compute the informations for the
    %tracking of the volleyball. 
    %   It keeps the memory of the tracking and also validte the tracking
    %   during the process.
    
    properties
        image_coordinate;           % where the ball is detected/predicted during tracking
        radii;                      % radius of the ball during tracking
        bbox;                       % bbox of the ball during tracking
        state;                      % state of the ball at that time instant:
                                    %    - known : for sure or with high
                                    %    probability - predicted : first
                                    %    step of assignement is predict the
                                    %    location - not_assigned : is still
                                    %    predicted but no circle has been
                                    %    found to match - unknown : this is
                                    %    the predicted location, but not
                                    %    even blob matches have been found,
                                    %    thus it is hard to trust
                                    
                                    
        total_visible_count;        % how many times the ball has been "known" in the history
        consecutive_invisible;      % how many consecutive steps the ball has been "unknown"
        starting_side;              % which side of the pitch the ball starts
        
        speed;                      % speed of the ball, useful only during tracking for prediction
        
        % CONIC INFO
        C_eq = [];
        C_C = [];
        C_linparam = [];
        
        % QUADRIC (CONE) INFO
        Q_eq = [];
        Q_Q = [];
        Q_lin = [];
        
        % PLANE INFO 
        P_eq = [];
        P_P = [];
        
        % the 3 coordinate of the set of points where the action takes
        % place will be saved here.
        trajectory3d = [];
        
    end
    
    properties (Access=private)
        point1_plane = [];          % the points on the plan ewhere the 
        point2_plane = [];          % action takes place.
        
        start_tracking_time = 0;    % start of the tracking time [s]
        
        end_flag = 0;               % flag that explains how the action ends:
                                    % when 0 ends due to time expiration. 
                                    % when 1 ends due to consecutive
                                    % invisible
                                    % when 2 ends due to hit on the net 
        
        net = [];                   % struct containing the info of the ner
                                    % net.x x coordinate of the vertices
                                    % net.y y " "
                                    % net.poly polyshape object of the net
    end
    
    methods
        function obj = history_tracker()
            %HISTORY_TRACKER Construct an instance of this class
            %   No informations are needed it just creates the object and
            %   allocate the first space.
            obj.image_coordinate{1} = [];
            obj.radii{1} = [];
            obj.bbox{1} = [];
            obj.state{1} = "unknown";
            
            obj.total_visible_count = 0;
            obj.consecutive_invisible = 0;
            obj.starting_side = 0;
            obj.speed = [0, 0];
            
        end
        
        % ok add, mai usata
        function obj = add(obj,varargin)
            %ADD adds a new detection on the object 
            
            if nargin == 1
                obj.image_coordinate{end + 1} = [];
                obj.bbox{end + 1} = [];
                obj.radii{end + 1} = [];
                obj.state{end + 1} = "unknown";
                
                %unchanged obj.total_visible_count;
                obj.consecutive_invisible = obj.consecutive_invisible +1;
                
            else
                obj.image_coordinate{end + 1} = varargin{1};
                obj.bbox{end + 1} = varargin{2};
                obj.state{end + 1} = varargin{3};
            end
        end
        
        %% prediction
        function obj = predict_location( obj  )
            %PREDICT_LOCATION Based on history predicts the new step
            
            % if previous is unknown or is the beginning predict in the
            % same point
            if obj.length == 1 | strcmp ( obj.state{end-1}, "unknown" )>0 %#ok<OR2>
                % repeat the same point
                % set to predicted
                % length = length +1
                obj.bbox{end+1} = obj.bbox{end};
                obj.radii{end+1} = obj.radii{end};
                obj.image_coordinate{end+1} = obj.image_coordinate{end};
                obj.state{end+1} = "predicted";
                
                % unchanged obj.total_visible_count
                obj.consecutive_invisible = obj.consecutive_invisible + 1;
                return;
            end
            
            
            % otherwise
            %liinear interp with old points
            
            % frame rate for speed
            d_t = 1/25;
            current.radii = obj.radii{end};
            current.bbox = obj.bbox{end};
            current.image_coordinate = obj.image_coordinate{end};
            
            %costant speed costant direction 
            % 2 step ahead because speed is always a step behind 
            obj.image_coordinate{end+1} = current.image_coordinate + obj.speed*d_t*2;
            
            % save the prediction
            obj.radii{end +1} = current.radii;
            obj.bbox{end+1} = bbox_from_circle( current.image_coordinate, current.radii, 'std');
            obj.state{end+1} = "predicted";
            
            % unchanged obj.total_visible_count
            obj.consecutive_invisible = obj.consecutive_invisible + 1;
        end
        
        %% Assignment
        function [obj, flag] = assignment(  obj, report )
            %ASSIGNMENT Assign from the report the best match to the last
            %predicted position
            flag = 1;
            if strcmp( obj.state{end}, "known" )
                % if it's known I'm ok with that
                return;
            end
            
            % get the n  closest to prediction,
            n = 10;
            v_set = obj.select_strongest( n, report);
            
            % for every of them, compute J as cost function
            x = obj.J_values( v_set, report.hsv );
            lambda = [1, 10, 30];
            J = lambda * x';
            
            % cost of marking the prediction wrong
            cost_non_assignment = 110; % 70 pixel from prevision and 30 of color 30 f0r match
            % take min J idx
            [m, n] = min( J ) ;
            
            % so if the best match is good enough then I decide it is the
            % ball
            if m < cost_non_assignment
                % assign it to obj.ball
                obj.image_coordinate{ end } = v_set.centers( n, :);
                obj.radii{ end } = v_set.radii( n );
                obj.bbox{ end } = bbox_from_circle( v_set.centers( n, : ), v_set.radii( n ), 'std' );
                obj.state{ end } = "known";
                obj.total_visible_count = obj.total_visible_count + 1;
                obj.consecutive_invisible = 0;
                
                % update also speed like it were a Kalman filter, thus I
                % keep memory of the speed
                r = 0.7;
                obj.speed = r*obj.speed + (1-r)*(obj.image_coordinate{ end } -obj.image_coordinate{ end-1 } )*25;
                flag = 0;
            else
                % switch the state of the prediciton
                if strcmp( obj.state{end}, "predicted" )
                    obj.state{end} = "not_assigned";
                else
                    obj.state{end} = "unknown";
                end
            end
        end
        
        function obj = discard_last( obj, varargin )
            %DISCARD_LAST remove the last object in the history
            % Two reason may be why we want it to be deleted. because we
            % want to (forced) because we lost the ball too many steps ago
            if ( nargin > 2 & strcmp(varargin{1}, "forced")>0) | (obj.consecutive_invisible > 10) %#ok<OR2,AND2>
                obj.image_coordinate{1} = [];
                obj.bbox{end} = [];
                obj.state{end} = "unknown";
                obj.consecutive_invisible = 1;
            end
        end
        
        function set_ = select_strongest( obj, quantity, report )
            %SELECT_STRONGEST From report select the strongest circles or
            %bbox that matches the prediction
            if strcmp( obj.state{end}, "predicted" )
                % if still rpedicted look for circles 
                set_ = obj.select_strongest_circles( report );
                
            else % it is "not_assigned"
                % if not assigned I've already looked for circle now I'll
                % look for bbox
                set_ = obj.select_strongest_blobs( report );
            end
            
            % To save just the best requested results, I erase the worst ones.
            % also keeps the number limited
            if set_.length > quantity
                idx = set_.length - quantity;
                while idx
                    [~, M] = max( set_.d_prev );
                    
                    set_.length = set_.length -1;
                    set_.centers( M, : ) = [];
                    set_.radii( M, : ) = [];
                    set_.connect( M, : ) = [];
                    set_.d_prev( M, : ) = [];
                    idx = idx -1;
                end
            end
        end
        
        function set_ = select_strongest_circles( obj, report  )
            %SELECT_STRONGEST_CIRCLES Extract the most closed to prediction
            %circles
            
            % allocate set_
            set_.length = 0;
            set_.centers = [];
            set_.radii = [];
            set_.d_prev = [];
            set_.connect = [];  % idx of circles in stepper that are 
                                % connected to those of foreground 
            
            % first I analyse the foreground
            if report.foreground.c_number>0
                % if something has been found
                
                % get the distances from prevision
                distances=  obj.image_coordinate{end} - report.foreground.c_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                % format the matches
                set_.length = report.foreground.c_number;
                set_.centers = report.foreground.c_centers;
                set_.radii = report.foreground.c_radii;
                set_.d_prev = distances;
                set_.connect = zeros( set_.length, 1);
                
            end
            
            % second one is stepper
            % I compute the distance of every of these circles to the
            % ones of f_set. If close enough, I merge them.
            if report.stepper.c_number>0
                % compute distances from prevision
                distances=  obj.image_coordinate{end} - report.stepper.c_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                % add them to matches 
                set_.length = set_.length + report.stepper.c_number;
                set_.centers = [set_.centers; report.stepper.c_centers];
                set_.radii = [set_.radii; report.stepper.c_radii];
                set_.d_prev = [set_.d_prev; distances] ;
                set_.connect = [set_.connect; zeros( report.stepper.c_number, 1)];
                
                % now remove circle that should represent them. Two circles
                % are defined as the same if, the intersect
                idx = 1;
                while idx < set_.length
                    % distance bewteen the two circles
                    distances=  set_.centers(idx, :) - set_.centers( idx+1:end, :);
                    distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                    
                    [m, n] = min( distances );
                    % if less then diameter they are intersecting
                    if m < 2*obj.radii{end}
                        % remove the second one
                        set_.connect( idx ) = idx + n - report.foreground.c_number;
                        set_.length = set_.length -1;
                        set_.centers( idx + n, : ) = [];
                        set_.radii( idx+n, : ) = [];
                        set_.d_prev( idx +n, : ) = [];
                        set_.connect( idx+n, : )  = [];
                    end
                    idx = idx +1;
                end
            end
        end
        
        function set_ = select_strongest_blobs( obj, report )
            % SELECT_STRONGEST_BLOBS Select the best blob that matches the
            % prediction of the ball
            
            % create struct set_
            set_.length = 0;
            set_.centers = [];
            set_.radii = [];
            set_.d_prev = [];
            set_.connect = [];  
            
            % just on the stepper!! 
            if report.stepper.b_number>0
                % if something exist
                
                % get distances
                distances=  obj.image_coordinate{end} - report.stepper.b_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                %add to the structure
                set_.length = report.stepper.b_number;
                set_.centers =  report.stepper.b_centers ;
                set_.radii =  report.stepper.b_radii;
                set_.d_prev = distances ;
                set_.connect = zeros( report.stepper.b_number, 1);
            end
            
            
        end
        
        function x = J_values( ~, v_set, color_mask)
            %J_VALUES Create the variables to compute the cost function
            if v_set.length == 0
                % if nothing present set to infinity
                
                x = [inf, inf, inf];
                return;
            end
            
            % x1
            % parameter 1 is distance from prevision
            distance_from_prev = v_set.d_prev ;
            
            % x2
            % parameter 2 is how much yellow there is in the bbox
            color_ratio = zeros( v_set.length, 1);
            for idx = 1: v_set.length
                [mask, ~, ~] = extract_roi( color_mask, v_set.centers( idx, : ), v_set.radii( idx ) );
                
                color_ratio(idx) = 1 - sum( mask, 'all' )/ ( size(mask, 1)* size(mask, 2) );
            end
            
            not_matched = double( v_set.connect == 0);
            
            % place them
            x = [ distance_from_prev, color_ratio not_matched ];
        end
        
        %% recovery
        function obj = recover( obj , infos )
            % RECOVER Prepared for recovery of the lost ball 
            steps = size(infos, 1);
            
            figure;
            pos = obj.image_coordinate{end-steps+1};
            plot( pos(1), pos(2) , 'or');
            hold on;
            
            colors = 'bkg';
            for idx = 1:steps-1
                pos = infos(idx).reports;
                pos = pos.stepper.b_centers;
                if ~isempty( pos )
                    plot( pos(:, 1), pos(:, 2), 'o', 'Color', colors(idx));
                end
            end
        end
        
        %% set get
        function obj = set_point( obj, which_one , point )
            %SET_POINT Sets one of the two points of motion plane in the
            %tracker
            if which_one == 1
                obj.point1_plane = point;
            else 
                obj.point2_plane = point;
            end
        end
        
        function out = get_point( obj, which_one)
            %GET_POINT Gets one of the two points of motion plane.
            if which_one == 1
                out = obj.point1_plane;
            else 
                out = obj.point2_plane;
            end
        end
        
        function obj = set_starttime( obj, time )
            %SET_STARTTIME Sets the starting time for tracking the ball
            obj.start_tracking_time = time;
        end
        
        function out = get_starttime( obj )
            %GET_STARTTIME gets the time istant at which tracking should
            %start.
            out =  obj.start_tracking_time;
        end
        
        function obj = set_net( obj, net)
            %SET_NET Save the net of the pitch where the action is taking
            %place.
            obj.net = net;
        end
        
        function out = get_net( obj)
            %GET_NET Returns the net struct of the pitch where the action
            %is taking place.
            out  = obj.net;
        end
        
        function out = length( obj )
            %LENGTH Answer the number of frame the object is been tracking.
            
            out = size(obj.state, 2);
        end
        
        function out = last_known( obj )
            %LAST_KNOWN Returns the coordinates of the last "known" point. 
           
            p = obj.get_known_positions;
            
            out = p(end, :);
        end
        
        function out = get_known_positions( obj )
            %GET_KNOWN_POSITIONS Returns all the points that are for sure
            %known.
            
            p = obj.image_coordinate';
            p = cell2mat( p );
            
            knownp = strcmpi( [obj.state{:}], "known" );
            
            out = p( knownp, : );
        end
            
        %% TRACKING ANALYSIS
        
        function out = stop_tracking( obj )
            
            out = (obj.end_flag ~= 0);
        end
        
        function out = get_end( obj )
            
            
            out= obj.end_flag;
        end
        
        function obj = check_end( obj )
            
            obj = obj.is_lost;
            
            obj = obj.hits_net;
        end
        
        function obj = is_lost( obj )
            %IS_LOST Returns if in the last 5 steps the ball is unknown. 
            
           obj.end_flag = obj.consecutive_invisible > 5;
        end
        
       
        function obj = hits_net( obj )
            %HITS_NET Understands if the ball has stopped onto the net. 
        
            % take last point for speed
            p(1, :) = obj.image_coordinate{end};
            
            % if it is on the net, and we have more point before that
            if inpolygon( p(1, 1), p(1, 2), obj.net.x, obj.net.y ) 
               p = obj.get_known_positions;
               
               % look how many points are on the net. Usually the ball
               % goes faster over the net and doesn't stop there. 
               p_on_net = inpolygon( p(:, 1), p(:, 2), obj.net.x, obj.net.y );
               
               % count how many
               % more then 3 points on the net means it has stopped there.
               enough = sum( p_on_net ) >= 3;
               
               if enough
                   % look if it is moving down
                   % take the ones on the net
                   p = p( p_on_net, :);
                   % last one is "end" of the tracking also
                   % remove it to see how much it has moved along x
                   p = p - p(end, :);
                   
                   % falling if along x is less then a quantity and y is
                   % increasing, actually the highest is the last one is
                   % perfect.
                   [~, Midx] = max( p(:,2) );
                   falling = (sum( p(:,1) ) < 30) & (Midx == size( p, 1) );
                   
                   if falling
                       
                       obj.end_flag = 2;
                   end
               end
            end
            
            
            %IMPROVEMENTS:
            % actually you should also chechk that is moving along y only
            % you should not count the unknown ones, maybe it founds the
            % ball 3 steps later. 
        end
    end
end

