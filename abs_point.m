classdef abs_point
    %ABS_POINT class to use well the points and not confuse them with lines
    
    properties
        params(3, 1) {mustBeReal}
        letter
    end
    
    methods
        function obj = abs_point( point_ , letter)
            %ABS_POINT Construct an instance of this class
            %   coordinates and eventually a letter to name it in pictures
            if nargin == 1
                obj.params = point_;
                obj.letter = [];
            elseif nargin == 2
                obj.params = point_;
                obj.letter = letter;
            else
                obj.params = [0;0;1];
                obj.letter = [];
            end
        end
        
        function obj = sinqle_acq(obj)
            %SINGLE_ACQ Acquires manually one point from the image 
            % you can choose multiples, but successive from first are neglected
            figure(gcf);
            [x_, y_]=getpts;
            obj.params = [x_(1), y_(1), 1]';
        end
        
        function obj = draw(obj, varargin)
            %DRAW Draw the point, eventually with its tag
            
            if( nargin >1 && strcmp( varargin{1} , 'at') )
                % if where to plot is passed
                figure(varargin{2});
            else
                figure(gcf);
            end
            
            hold on;
            plot( obj.params(1), obj.params(2),'.r','MarkerSize',12, 'LineWidth', 3);
            if( ~isempty(obj.letter) )
                text( obj.params(1), obj.params(2), obj.letter, 'FontSize', 20, 'Color', 'r')
            end
            hold off;
        end
        
        function outputArg = passing_line(obj,obj2)
            %PASSING_LINE given two points, which line goes by
            outputArg = cross(obj.params, obj2.params);
            outputArg = outputArg/outputArg(3);
        end
        
        function obj = normalize (obj )
            %NORMALIZE Normalizes coordinates
            obj.params = obj.params ./ obj.params(3);
            
        end
        
        function obj = transform (obj, H)
            %TRANSFORM Transform H is applied
            obj.params = H * obj.params ;
        end
        
        function y_n = is_valid(obj)
            %IS_VALID Tell's you if is the point at the infinity. I should
            %not create them usually.
            if( sum(obj.params == [0,0,1]') ~= 3 )
                y_n = 1;
            else
                y_n = 0;
            end
        end
    end
end