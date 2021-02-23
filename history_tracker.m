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
        function obj = predict_location( obj , frame ) %#ok<INUSD>
            % se il precedente è unknown
            % chiedi punt
            if strcmp ( obj.state{end} , "unknown" )
                %acquire pts from image
                % set to known
                % length = +1
                
                return;
            end
            
            % se il precedente è known o predicted
            % se il pre preceente è unknown o non esiste
            %same point
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
            
            current.radii = obj.radii{end};
            current.bbox = obj.bbox{end};
            current.image_coordinate = obj.image_coordinate{end};
            previous.bbox = obj.bbox{end};
            previous.image_coordinate = obj.image_coordinate{end};
            
            %costant speed costant direction
            obj.image_coordinate{end+1} = current.image_coordinate + (current.image_coordinate - previous.image_coordinate);
            % skip for now
            %out_.hsv_scale
            % dimension constant scaling wrt to previous area
            A_1 = current.bbox(4)*current.bbox(3);
            A_2 = previous.bbox(4)*previous.bbox(3);
            new_area = current.bbox(3:4)*A_1/A_2;
            new_top = current.bbox(1:2) - ceil ((new_area-current.bbox(3:4))/2) ;
            
            obj.radii{end +1} = current.radii*A_1/A_2;
            obj.bbox{end+1} = [new_top, new_area] ;
            obj.state{end+1} = "predicted";
            obj.length = obj.length + 1;
            % unchanged obj.total_visible_count
            obj.consecutive_invisible = obj.consecutive_invisible + 1;
        end
        
        % da fare forte
        function obj = assignment(  obj, varargin )
            if strcmp( obj.state{end}, "known" )
                return;
            end
            %If i decide that the prevision is correct, I need to increase
            %total visible count and set to 0 consecutive invisible
            
            if strcmp( obj.state{end}, "predicted" )
                f_set = varargin{1};
                h_set = varargin{2};
                s_set = varargin{3};
                % get the n closest to prediction,
                f_set = obj.select_strongest( f_set, 10 );
                
                % for every of them, compute J
                x = obj.J_values( f_set, h_set, s_set );
                lambda = [1, 1, 1, 1, 1];
                J = lambda * x';
                
                % take min J idx
                [~, n] = min( J ) ;
                
                % assign it to obj.ball
                obj.image_coordinate{ end } = f_set.centers{ n };
                obj.radii{ end } = f_set.radii{ n };
                obj.bbox{ end } = ...
                    [ floor( f_set.centers{ n } - f_set.radii{ n } ), ...
                    2*ceil( [f_set.radii{ n }, f_set.radii{ n }] )];
                obj.state{ end } = "known";
                obj.total_visible_count = obj.total_visible_count + 1;
                obj.consecutive_invisible = 0;
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
        
        function set_ = select_strongest( obj, set , quantity )
            distances = zeros( set.length, 1);
            for idx = 1: set.length
                distances( idx ) = norm( obj.image_coordinate{end} - set.centers{ idx, : } ) ;
            end
            
            set_.length = min( quantity, set.length ) ;
            set_.centers = cell( set_.length, 1);
            set_.radii = cell( set_.length, 1);
            set_.d_prev = cell( set_.length, 1);
            set_.mask = set.mask;
            for idx = 1: set_.length
                [m, n] = min( distances );
                
                %copy
                set_.centers{ idx } = set.centers{ n, : };
                set_.radii{ idx } = set.radii{ n };
                set_.d_prev{ idx } = m;
                
                % remove the used one
                distances( n ) = max( distances) ;
            end
        end
        
        function x = J_values( obj, f_set, h_set, s_set )
            % x1
            distances_from_old = zeros( f_set.length, 1);
            for idx = 1: f_set.length
                distances_from_old( idx ) = norm( obj.image_coordinate{ end-1 } - f_set.centers{ idx, : } ) ;
            end
            
            % x2
            distance_from_prev = zeros( f_set.length, 1);
            for idx = 1: f_set.length
                distance_from_prev( idx ) = f_set.d_prev{ idx } ;
            end
            
            % x3
            d_ratio = zeros( f_set.length, 1);
            for idx = 1: f_set.length
                d_ratio( idx ) = f_set.radii{ idx } / obj.radii{ end-1 };
            end
            
            % x4
            max_d = 15;
            %min between 2*ma_d and actual distance from the closest circle
            %found in s_mask
            distance_from_s = zeros( f_set.length, 1);
            for idx = 1: f_set.length
                d_f_s_jdx = norm( f_set.centers{ idx, : } - s_set.centers{ 1 } );
                distance_from_s( idx ) = min( d_f_s_jdx, 2*max_d ) ;
                
                for jdx = 2: size( s_set.centers, 1 )
                    d_f_s_jdx = norm( f_set.centers{ idx, : } - s_set.centers{ jdx } );
                    d_f_s_idx = distance_from_s( idx );
                    distance_from_s( idx ) = ...
                        min( [d_f_s_idx, d_f_s_jdx, 2*max_d] );
                end
            end
            
            % x5
            color_ratio = zeros( f_set.length, 1);
            for idx = 1: f_set.length
                bboxes( 1:2 ) = floor( f_set.centers{ idx } - f_set.radii{ idx } );
                bboxes( 3:4 ) = 2*ceil( [f_set.radii{ idx }, f_set.radii{ idx }] );
                temp = h_set.mask( bboxes(2):bboxes(2)+bboxes(4), bboxes(1):bboxes(1)+bboxes(3) );
                color_ratio(idx) = 1 - sum( temp, 'all' )/( bboxes(3)*bboxes(4) );
            end
            
            x = [ distances_from_old, distance_from_prev, d_ratio, distance_from_s, color_ratio ];
        end
    end
end

