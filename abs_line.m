classdef abs_line
    %ABS_LINE ad hoc class for 2d line
    %   To shorten some steps I created a class that fits the way I want to
    %   code
    
    properties
        params(3, 1) {mustBeReal}
        p1 (3, 1) {mustBeReal}
        p2 (3, 1) {mustBeReal}
    end
    
    methods
        
        function obj = abs_line( varargin )
            %ABS_LINE Create an istane of this class
            % It can have only the line as input or the line and two points
            % on it. If it is just the line it finds the two points
            % crossing with the axis
            if nargin == 1
                line_ = varargin{1};
                obj.params = line_ ;
                obj.p1 = cross( line_, [1; 0; 0] ); 
                obj.p1 = obj.p1 / (obj.p1(3) );
                obj.p2 = cross( line_, [0; 1; 0] ); 
                obj.p2 = obj.p2 / (obj.p2(3) );
            elseif nargin == 3
                obj.params = varargin{1};
                obj.p1 = varargin{2}; 
                obj.p2 = varargin{3}; 
            else
                obj.params = [0;0;1];
            end
        end
        
        function obj = acquire_from_image(obj)
            %ACQUIRE_FROM_IMAGE Acquire a line by manually drawing it.
            %when I need to pick it manually
            figure(gcf);
            segment1 = drawline('Color','b');
            obj.p1 = [ (segment1.Position(1, :))' ;  1];
            obj.p2 = [ (segment1.Position(2, :))'; 1];
            obj.params = cross( obj.p1 , obj.p2 );
            obj.params = obj.params ./ obj.params(3);
        end
        
        function obj = draw(obj, varargin)
            %DRAW Draw the line in current figure
            % additional inputs couple name value 
            % figure handler
            % Insideborders for draw a line that goes from one border to
            % the other of the image
            % usual stuff, color and thickness
            f_h = figure(gcf);
            p_ = [obj.p1(1:2), obj.p2(1:2)];
            color = 'r';
            thickness = 0.5;
            
            idx = 1;
            while idx < (nargin-1)
                if(strcmp( varargin{idx} , "at") )
                    % if the figure handler is passed use it
                    f_h = varargin{idx+1};
                    
                elseif ( strcmp( varargin{idx}, 'insideBorder') )
                    % if is requested to draw between the lines
                    x_limit = varargin{4}(2);
                    y_limit = varargin{4}(1);
                    p(:, 1) = cross( [1; 0; 0], obj.params );
                    p(:, 2) = cross( [0; 1; 0], obj.params );
                    p(:, 3) = cross( [1; 0; -x_limit], obj.params );
                    p(:, 4) = cross( [0; 1; -y_limit], obj.params );
                    p = p./p(3, :);
                    p = p( 1:2, : );
                    
                    p_ = zeros(2);
                    jdx = 1;
                    for ldx = 1:4
                        if (p(1, ldx) >= 0  &&  p(2, ldx) >= 0 )
                            p_(:,  jdx) = p(:, ldx);
                            jdx = jdx+1;
                        end
                    end
                    
                elseif(strcmp( varargin{idx} , 'Color') )
                    % required color 
                    color = varargin{idx+1};
                    
                elseif(strcmp( varargin{idx} , 'LineWidth') )
                    % required thickness
                    thickness = varargin{idx+1};
                    
                end
                idx = idx+2;
            end

            figure(f_h);
            hold on;
            plot(p_(1, :), p_(2, :),  'Color', color, 'LineWidth', thickness);
            hold off;
        end
        
        function outputArg = intersection(obj,obj2)
            %INTERSECTION intersection between two lines is a point
            %   Just uses the two lines as objects to find where they cross
            outputArg = cross(obj.params, obj2.params);
            outputArg = outputArg/outputArg(3);
        end
        
        function obj = normalize (obj )
            %NORMALIZE normalizes coordinates
            obj.params = obj.params ./ obj.params(3);
            obj.p1 = obj.p1 ./ obj.p1(3);
            obj.p2 = obj.p2 ./ obj.p2(3);
        end
        
        function obj = transform (obj, H) 
            %TRANSFORM Apply transformation H
            % in this way it was easyer to write in the main program so I
            % don't do mistakes in treating lines as points
           obj.params = inv(H)' * obj.params ;
           obj.p1 = H * obj.p1;
           obj.p2 = H * obj.p2;
        end
        
        function obj = reset_point (obj, line, varargin)
            %RESET_POINT find new point for the line as intersection
            %between the line itself and the one given
               if( nargin> 2 && varargin{1} == 1) 
                   obj.p1 = cross( obj.params, line);
                   obj.p1 = obj.p1/obj.p1(3);
               else
                   obj.p2 = cross( obj.params, line);
                   obj.p2 = obj.p2/obj.p2(3);
               end
        end
        
        function y_n = is_valid( obj )
            %IS_VALID I should not use the point at the infinty as a line
           if( sum(obj.params == [0, 0, 1]') ~=3 )
               y_n = 1;
           else
               y_n = 0;
           end
        end
        
        function angle = angle( obj )
            %ANGLE Returns the orientation of the line in radiant.
            
            angle = atan( obj.params(2)/ obj.params(1) );
        end
    end
end

