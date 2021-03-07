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
        
        function [obj, flag] = assignment(  obj, report )
            flag = 1;
            if strcmp( obj.state{end}, "known" )
                return;
            end
            
            % get the n  closest to prediction,
            n = 10;
            v_set = obj.select_strongest( n, report);
            
            % for every of them, compute J
            x = obj.J_values( v_set, report.hsv );
            
            
            
            lambda = [1, 30];
            J = lambda * x';
            
            cost_non_assignment = 100; % 40 pixel dalla prevision più 30 di color
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
                
                r = 0.7;
                obj.speed = r*obj.speed + (1-r)*(obj.image_coordinate{ end } -obj.image_coordinate{ end-1 } )*25;
                flag = 0;
            else
                if strcmp( obj.state{end}, "predicted" )
                    obj.state{end} = "not_assigned";
                else
                    obj.state{end} = "unknown";
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
        
        function set_ = select_strongest( obj, quantity, report )
            if strcmp( obj.state{end}, "predicted" )
                set_ = obj.select_strongest_circles( report );
            else % it is "not_assigned"
                set_ = obj.select_strongest_blobs( report );
            end
            
            % To save just the best requested results, I erase the worst ones.
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
        
        function set_ = select_strongest_circles( obj, report  )
            % allocate set_
            set_.length = 0;
            set_.centers = [];
            set_.radii = [];
            set_.d_prev = [];
            set_.connect = [];  % idx of s_set where it is connected to
            
            if report.foreground.c_number>0
                distances=  obj.image_coordinate{end} - report.foreground.c_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                set_.length = report.foreground.c_number;
                set_.centers = report.foreground.c_centers;
                set_.radii = report.foreground.c_radii;
                set_.d_prev = distances;
                set_.connect = zeros( set_.length, 1);
                
            end
            
            % second one is s_set
            % I compute the distance of every of these circles to the
            % ones of f_set. If close enough, I merge them.
            if report.stepper.c_number>0
                distances=  obj.image_coordinate{end} - report.stepper.c_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                set_.length = set_.length + report.stepper.c_number;
                set_.centers = [set_.centers; report.stepper.c_centers];
                set_.radii = [set_.radii; report.stepper.c_radii];
                set_.d_prev = [set_.d_prev; distances] ;
                set_.connect = [set_.connect; zeros( report.stepper.c_number, 1)];
                
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
            end
        end
        
        function set_ = select_strongest_blobs( obj, report )
            % allocate set_
            set_.length = 0;
            set_.centers = [];
            set_.radii = [];
            set_.d_prev = [];
            set_.connect = [];  % idx of s_set where it is connected to
            
            if report.stepper.b_number>0
                distances=  obj.image_coordinate{end} - report.stepper.b_centers;
                distances = sqrt( distances(:,1).^2 + distances(:,2).^2 );
                
                set_.length = report.stepper.b_number;
                set_.centers =  report.stepper.b_centers ;
                set_.radii =  report.stepper.b_radii;
                set_.d_prev = distances ;
                set_.connect = zeros( report.stepper.b_number, 1);
            end
            
            
        end
        
        function x = J_values( ~, v_set, color_mask)
            if v_set.length == 0
                x = [inf, inf];
                return;
            end
            % x1
            distance_from_prev = v_set.d_prev ;
            
            % x5
            color_ratio = zeros( v_set.length, 1);
            for idx = 1: v_set.length
                [mask, ~, ~] = extract_roi( color_mask, v_set.centers( idx, : ), v_set.radii( idx ) );
                
                color_ratio(idx) = 1 - sum( mask, 'all' )/ ( size(mask, 1)* size(mask, 2) );
            end
            
            x = [ distance_from_prev, color_ratio ];
            
        end
        
        function out = is_lost( obj )
            st_1 = obj.state{end};
            st_2 = obj.state{end-1};
            st_3 = obj.state{end-2};
            
            comp = "unknown";
            
            out = ( strcmp( st_1, comp) & strcmp( st_2, comp) & strcmp( st_3, comp) );
        end
        
        function obj = recover( obj , infos )
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
    end
end

