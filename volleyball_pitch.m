classdef volleyball_pitch
    %VOLLEYBALL_PITCH Class to save the parameters of a volleyball pitch
    %   A pitch can be real, then classic position are inserted, otherwise
    %   if it's on the image use the add_point method and pass the image of
    %   the pitch
    
    properties
        pitch(14, 1) = abs_point();
        image_tp
    end
    
    methods
        function obj = volleyball_pitch( varargin )
            %VOLLEYBALL_PITCH Construct an instance of this class
            %   We have from A to J on the pitch
            % A' and F' top of the net
            % A'' and F'' bottom of the net
            % If is real don't insert anything, otherwise insert something
            % just to know
            
            
            
            if nargin >0
                obj.image_tp = varargin{1};
            else
                %net_height = 2.24; %m %femminile
                net_height = 2.43; %m
                %obj.pitch(14, 1) = abs_point();
                obj.pitch(1) = abs_point([0, 0, 0]', 'A');
                obj.pitch(2) = abs_point([3, 0, 0]', 'B');
                obj.pitch(3) = abs_point([9, 0, 0]', 'C');
                obj.pitch(4) = abs_point([9, 9, 0]', 'D');
                obj.pitch(5) = abs_point([3, 9, 0]', 'E');
                obj.pitch(6) = abs_point([0, 9, 0]', 'F');
                obj.pitch(7) = abs_point([-3, 9, 0]', 'G');
                obj.pitch(8) = abs_point([-9, 9, 0]', 'H');
                obj.pitch(9) = abs_point([-9, 0, 0]', 'I');
                obj.pitch(10) = abs_point([-3, 0, 0]', 'J');
                obj.pitch(11) = abs_point([0, 0, net_height]', 'A_');
                obj.pitch(12) = abs_point([0, 9, net_height]', 'F_');
                obj.pitch(13) = abs_point([0, 0, net_height-1]', 'A__');
                obj.pitch(14) = abs_point([0, 9, net_height-1]', 'F__');
                obj.image_tp = 0;
            end
        end
        
        function  draw(obj)
            %DRAW Draw the pitch
            %   Detailed explanation goes here
            if(  obj.image_tp == 0 )
                figure;
                %Draw from each point on the ground to the next one
                for idx = 1:9
                    plot3( obj.pitch(idx).params(1), obj.pitch(idx).params(2), ...
                        obj.pitch(idx).params(3), '*r');
                    grid on;
                    hold on;
                    plot3( [obj.pitch(idx).params(1), obj.pitch(idx+1).params(1)],...
                        [obj.pitch(idx).params(2), obj.pitch(idx+1).params(2)],...
                        [obj.pitch(idx).params(3), obj.pitch(idx+1).params(3)], '-r');
                end
                %close the circle
                plot3( obj.pitch(10).params(1), obj.pitch(10).params(2), ...
                    obj.pitch(10).params(3), '*r');
                plot3( [obj.pitch(10).params(1), obj.pitch(1).params(1)],...
                    [obj.pitch(10).params(2), obj.pitch(1).params(2)],...
                    [obj.pitch(10).params(3), obj.pitch(1).params(3)], '-r');
                % 3 middle lines
                plot3( [obj.pitch(1).params(1), obj.pitch(6).params(1)],...
                    [obj.pitch(1).params(2), obj.pitch(6).params(2)],...
                    [obj.pitch(1).params(3), obj.pitch(6).params(3)], '-r');
                plot3( [obj.pitch(2).params(1), obj.pitch(5).params(1)],...
                    [obj.pitch(2).params(2), obj.pitch(5).params(2)],...
                    [obj.pitch(2).params(3), obj.pitch(5).params(3)], '-r');
                plot3( [obj.pitch(10).params(1), obj.pitch(7).params(1)], ...
                    [obj.pitch(10).params(2), obj.pitch(7).params(2)],...
                    [obj.pitch(10).params(3), obj.pitch(7).params(3)], '-r');
                
                %post 1
                plot3( [obj.pitch(1).params(1), obj.pitch(11).params(1)], ...
                    [obj.pitch(1).params(2), obj.pitch(11).params(2)],...
                    [obj.pitch(1).params(3), obj.pitch(11).params(3)], '-b', 'LineWidth', 5);
                %post 2
                plot3( [obj.pitch(6, 1).params(1), obj.pitch(12).params(1)], ...
                    [obj.pitch(6).params(2), obj.pitch(12).params(2)],...
                    [obj.pitch(6).params(3), obj.pitch(12).params(3)], '-b', 'LineWidth', 5);
                %net up
                plot3( [obj.pitch(11).params(1), obj.pitch(12).params(1)], ...
                    [obj.pitch(11).params(2), obj.pitch(12).params(2)],...
                    [obj.pitch(11).params(3), obj.pitch(12).params(3)], '--k');
                %net down
                plot3( [obj.pitch(13).params(1), obj.pitch(14).params(1)],...
                    [obj.pitch(13).params(2), obj.pitch(14).params(2)],...
                    [obj.pitch(13).params(3), obj.pitch(14).params(3)], '--k');
            else
                f_h = figure;
                imshow(obj.image_tp);
                
                for idx = 1:14
                    if ( obj.pitch(idx).is_valid() )
                        obj.pitch(idx).draw('at', f_h);
                    end
                end
            end
        end
        
        function num = mapper( obj, letter)
            switch letter
                
                case 'A'
                    num = 1;
                case 'B'
                    num = 2;
                case 'C'
                    num = 3;
                case 'D'
                    num = 4;
                case 'E'
                    num = 5;
                case 'F'
                    num = 6;
                case 'G'
                    num = 7;
                case 'H'
                    num = 8;
                case 'I'
                    num = 9;
                case 'J'
                    num = 10;
                case 'A_'
                    num = 11;
                case 'F_'
                    num = 12;
                case 'A__'
                    num = 13;
                case 'F__'
                    num = 14;
            end
        end
        
        function  obj = add_point(obj,line_1, line_2, letter )
            %ADD_POINT give new coordinates for a pitch only for image
            %pitch
            %   Detailed explanation goes here
            % If one of the two lines doesn't exist do nothing
            if ( line_1.is_valid() | line_2.is_valid() ) %#ok<OR2>
                return;
            else
                %assign the point to the right place
                obj.pitch( obj.mapper(letter) ) = abs_point(line_1.intersection( line_2 ) , letter);
            end
        end
        
    end
end