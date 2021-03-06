classdef history_tracker
    %history_tracker Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_coordinate;
        radii;
        %hsv_scale;
        bbox;
        state;
        total_visible_count;
        consecutive_invisible;
        length;
        starting_side;
        
        speed;
        
    end
    
    methods
        function obj = history_tracker()
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.image_coordinate{1} = [];
            obj.radii{1} = [];
            obj.bbox{1} = [];
            obj.state{1} = "unknown";
            obj.length = 0;
            obj.total_visible_count = 0;
            obj.consecutive_invisible = 0;
            obj.starting_side = 0;
            obj.speed = [0, 0];
            
        end
        
        % ok add, mai usata
        function obj = add(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if nargin == 1
                obj.image_coordinate{end + 1} = [];
                obj.bbox{end + 1} = [];
                obj.radii{end + 1} = [];
                obj.state{end + 1} = "unknown";
                obj.length = obj.length + 1;
                %unchanged obj.total_visible_count;
                obj.consecutive_invisible = obj.consecutive_invisible +1;
            else
                obj.image_coordinate{end + 1} = varargin{1};
                obj.bbox{end + 1} = varargin{2};
                obj.state{end + 1} = varargin{3};
                obj.length = obj.length + 1;
            end
        end
        
        %ok predict
        function obj = predict_location( obj  )
            
            % se il precedente è known o predicted
            % se il pre preceente è unknown o non esiste
            % same point
            if obj.length == 1 | strcmp ( obj.state{end-1}, "unknown" )
                % repeat the same point
                % set to predicted
                % length = length +1
                obj.bbox{end+1} = obj.bbox{end};
                obj.radii{end+1} = obj.radii{end};
                obj.image_coordinate{end+1} = obj.image_coordinate{end};
                obj.state{end+1} = "predicted";
                obj.length = obj.length+1;
                % unchanged obj.total_visible_count
                obj.consecutive_invisible = obj.consecutive_invisible + 1;
                return;
            end
            
            
            % altrimenti
            %liinear interp
            
            d_t = 1/25;
            current.radii = obj.radii{end};
            current.bbox = obj.bbox{end};
            current.image_coordinate = obj.image_coordinate{end};
            
            %             previous.bbox = obj.bbox{end-1};
            %             previous.image_coordinate = obj.image_coordinate{end-1};
            %
            %costant speed costant direction
            %obj.image_coordinate{end+1} = current.image_coordinate + (current.image_coordinate - previous.image_coordinate);
            obj.image_coordinate{end+1} = current.image_coordinate + obj.speed*d_t*2;
            
            
            obj.radii{end +1} = current.radii;
            obj.bbox{end+1} = bbox_from_circle( current.image_coordinate, current.radii, 'std');
            obj.state{end+1} = "predicted";
            obj.length = obj.length + 1;
            % unchanged obj.total_visible_count
            obj.consecutive_invisible = obj.consecutive_invisible + 1;
        end
        
        % ok first version
        function obj = assignment(  obj, report )
            if strcmp( obj.state{end}, "known" )
                return;
            end
            %If i decide that the prevision is correct, I need to increase
            %total visible count and set to 0 consecutive invisible
            
            if strcmp( obj.state{end}, "predicted" )
                
                % get the n  closest to prediction,
                n = 10;
                v_set = obj.select_strongest_circles( n, report);
                
                % for every of them, compute J
                x = obj.J_values( v_set, report.hsv );
                
                if size( x, 2) == 2
                    lambda = [1, 30];
                    J = lambda * x';
                    
                    cost_non_assignment = 70; % 40 pixel dalla prevision più 30 di color
                    % take min J idx
                    [m, n] = min( J ) ;
                    
                    if m < cost_non_assignment
                        % assign it to obj.ball
                        obj.image_coordinate{ end } = v_set.centers( n, :);
                        obj.radii{ end } = v_set.radii( n );
                        obj.bbox{ end } = bbox_from_circle( v_set.centers( n, : ), v_set.radii( n ), 'std' );
                        obj.state{ end } = "known";
                        obj.total_visible_count = obj.total_visible_count + 1;
                        obj.consecutive_invisible = 0;
                        
                        r = 0.8;
                        obj.speed = r*obj.speed + (1-r)*(obj.image_coordinate{ end } -obj.image_coordinate{ end-1 } )*25;
                    end
                end
            end
            
            
        end
        
        function obj = discard_last( obj, varargin )
            if ( nargin > 2 & strcmp(varargin{1}, "forced")) | (obj.consecutive_invisible > 10)
                obj.image_coordinate{1} = [];
                obj.bbox{end} = [];
                obj.state{end} = "unknown";
                obj.consecutive_invisible = 1;
            end
        end
        
        function set_ = select_strongest_circles( obj, quantity, report  )
            % allocate set_
            set_.length = 0;
            set_.centers = [];
            set_.radii = [];
            set_.d_prev = [];
            set_.connect = [];  % idx of s_set where it is connected to
            
            if report.foreground.c_number
                %                 distances = zeros( f_set.length, 1);
                %                 for idx = 1: f_set.length
                %                     distances( idx ) = norm( obj.image_coordinate{end} - f_set.centers{ idx, : } ) ;
                %                 end
                distances=  obj.image_coordinate{end} - report.foreground.c_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                set_.length = report.foreground.c_number;
                set_.centers = report.foreground.c_centers;
                set_.radii = report.foreground.c_radii;
                set_.d_prev = distances;
                set_.connect = zeros( set_.length, 1);
                
                %                 set_.length = min( quantity, report.foreground.c_number ) ;
                %                 set_.centers{ set_.length, 1} = 0;
                %                 set_.radii { set_.length, 1} = 0;
                %                 set_.d_prev{ set_.length, 1} = 0;
                %                 set_.connect{ set_.length, 1} = 0;
                %                 idx = 1;
                %                 max_ = max( distances) +1;
                %                 while idx <= set_.length
                %                     [m, n] = min( distances );
                %
                %                     %copy
                %                     set_.centers{ idx } = f_set.centers{ n, : };
                %                     set_.radii{ idx } = f_set.radii{ n };
                %                     set_.d_prev{ idx } = m;
                %                     set_.connect{ idx } = 0;
                %
                %                     % remove the used one
                %                     distances( n ) = max_ ;
                %                     idx = idx+1;
                %                 end
            end
            
            % second one is s_set
            % I compute the distance of every of these circles to the
            % ones of f_set i  close eneough
            if report.stepper.c_number
                distances=  obj.image_coordinate{end} - report.stepper.c_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                set_.length = set_.length + report.stepper.c_number;
                set_.centers = [set_.centers; report.stepper.c_centers];
                set_.radii = [set_.radii; report.stepper.c_radii];
                set_.d_prev = [set_.d_prev; distances] ;
                set_.connect = [set_.connect; zeros( report.stepper.c_number, 1)];
                
                %                 s_set = report.foreground;
                %                 distances = zeros( set_.length, s_set.c_number);
                %                 for jdx = 1:s_set.c_number
                %                     for idx = 1: set_.length
                %                         distances( idx, jdx ) = norm( s_set.centers( jdx , :) - set_.centers{ idx } ) ;
                %                     end
                %                 end
                %
                %                 kdx = min( set_.length, s_set.c_number ) ;
                %                 numbers = 1:s_set.c_number;
                %                 while kdx > 0 % and dim less then n
                %                     [m, n] = min( distances , [], 'all', 'linear');
                %                     if they intersect
                %                     if m <= 2*obj.radii{ end }
                %                         r = ceil( n/s_set.c_number ) ;
                %                         c = n- (r-1)*s_set.c_number ;
                %
                %
                %                         set_.connect{ r} = numbers(c);
                %                         numbers(c) = [];
                %
                %                         distances(r, :) = [];
                %                         distances(:, c) = [];
                %
                %
                %                         s_set.length = s_set.c_number -1;
                %                         s_set.centers(c, :) = [];
                %                         s_set.radii(c, :) = [];
                %                     end
                %
                %                     kdx = kdx-1;
                %                 end
                %
                %                 If I still have some circles not been asigned I add the
                %                 m to f_set
                %                 if s_set.c_number
                %                     distances = zeros( s_set.length, 1);
                %                     for idx = 1: s_set.length
                %                         distances( idx ) = norm( obj.image_coordinate{end} - s_set.centers{ idx, : } ) ;
                %                     end
                %                     distances=  obj.image_coordinate{end} - s_set.centers;
                %                     distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                %
                %                     idx = set_.length+1;
                %                     set_.length = set_.length + min( quantity, s_set.c_number ) ;
                %                     set_.centers{ set_.length, 1} = 0;
                %                     set_.radii { set_.length, 1} = 0;
                %                     set_.d_prev{ set_.length, 1} = 0;
                %                     set_.strength{ set_.length, 1} = 0;
                %
                %                     max_ = max( distances) +1;
                %                     while idx <= set_.length
                %                         [m, n] = min( distances );
                %
                %                         copy
                %                         set_.centers{ idx } = s_set.centers( n, : );
                %                         set_.radii{ idx } = s_set.radii( n, : );
                %                         set_.d_prev{ idx } = m;
                %                         set_.connect{ idx } = 0;
                %
                %                         remove the used one
                %                         distances( n ) = max_ ;
                %                         idx = idx+1;
                %                     end
                %                 end
                idx = 1;
                while idx < set_.length
                    distances=  set_.centers(idx, :) - set_.centers( idx+1:end, :);
                    distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                    
                    [m, n] = min( distances );
                    if m < 2*obj.radii{end}
                        set_.connect( idx ) = idx + n - report.foreground.c_number;
                        set_.length = set_.length -1;
                        set_.centers( idx + n, : ) = [];
                        set_.radii( idx+n, : ) = [];
                        set_.d_prev( idx +n, : ) = [];
                        set_.connect( idx+n, : )  = [];
                    end
                    idx = idx +1;
                end
                
                if set_.length > quantity
                    idx = set_.length - quantity;
                    while idx
                        [~, M] = max( set_.d_prev );
                        
                        set_.length = set_.length -1;
                        set_.centers( M, : ) = [];
                        set_.radii( M, : ) = [];
                        set_.connect( M, : ) = [];
                        set_.d_prev( M, : ) = [];
                    end
                end
                
            end
        end
        
        function x = J_values( ~, v_set, color_mask )
            
            % x1
            %             distance_from_prev = zeros( v_set.length, 1);
            %             for idx = 1: v_set.length
            %                 distance_from_prev( idx ) = v_set.d_prev{ idx } ;
            %             end
            distance_from_prev = v_set.d_prev ;
            
            % x5
            color_ratio = zeros( v_set.length, 1);
            for idx = 1: v_set.length
                [mask, ~, ~] = extract_roi( color_mask, v_set.centers( idx, : ), v_set.radii( idx ) );
                
                color_ratio(idx) = 1 - sum( mask, 'all' )/ ( size(mask, 1)* size(mask, 2) );
            end
            
            x = [ distance_from_prev, color_ratio ];
            
        end
    end
end

