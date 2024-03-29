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
            % Creates a pitch on the new figure.
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
                
                % in case is a projected pitch without an image
            elseif obj.image_tp == -1
                return;
                
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
            %ADD_POINT give new coordinates for a pitch( only for image
            %pitches)
            %pitch
            
            % If one of the two lines doesn't exist do nothing
            if ( ~line_1.is_valid() | ~line_2.is_valid() ) %#ok<OR2>
                return;
            else
                %assign the point to the right place
                obj.pitch( obj.mapper(letter) ) = abs_point(line_1.intersection( line_2 ) , letter);
            end
        end
        
        function [obj_, error] = complete(obj, P, real_pitch)
            %COMPLETE Creates a new istance of a pitch on the image
            % It projects all the real points on the image.
            % Plus it computes the average error between the new points and those that were present in the original image
            
            % project a real one
            obj_ = real_pitch.transform( P );
            % copy the background to reenable drawing
            obj_.image_tp = obj.image_tp;
            
            % compute error of projection
            error = 0;
            valid_points = 0;
            for idx = 1:14
                if( obj.pitch(idx).is_valid() && obj_.pitch(idx).is_valid())
                    d = obj_.pitch(idx).params(1:2)-obj.pitch(idx).params(1:2);
                    error = error + d'*d;
                    valid_points = valid_points +1;
                end
                
            end
            error = error/valid_points;
        end
        
        function obj_ = transform(obj, P)
            %TRANSFORM Creates a new istance of a pitch on the image
            %starting from a real one and a projection matrix
            
            % copy
            obj_ = obj;
            % change the points projecting
            for idx = 1:14
                %3x1 = 3x4 * [3x1; 1x1];
                obj_.pitch(idx).params = P* [obj.pitch(idx).params; 1];
                obj_.pitch(idx) = obj_.pitch(idx).normalize();
            end
            
            % disable drawing
            obj_.image_tp = -1;
        end
        
        function out = get_direction_of_play( obj, varargin )
            % GET_DIRECTION_OF_PLAY Answer with the angles that the line of
            % a projected pitch can stay to be moving along the direction
            % of play
            
            if obj.image_tp == 0 & nargin == 2 %#ok<AND2>
                P = varargin{1};
                
                proj = obj.transform( P );
            else
                
                proj = obj;
            end
            
            % now I can worrk with proj_pitch
            % line 1 through origin
            C = proj.pitch(3);
            I = proj.pitch(9);
            line1 = abs_line( passing_line( C, I ) );
            
            % line 2 opposite one
            D = proj.pitch(4);
            H = proj.pitch(8);
            line2 = abs_line( passing_line( D, H ) );
            
            l1a = line1.angle;
            l2a = line2.angle;
            
            out = [min(l1a, l2a), max(l1a, l2a)];
            
            
        end
        
        function net = get_net( obj, varargin )
            %GET_NET Returns the coordinate of the polygon describing the
            %net in the format that matlab uses to describes polygons: x
            %coordinates of the vertices and y coordinates of the vertices
            %on different arrays, same index means same vertex.
            % This is used beacuse it its laso the fromat that inpolygon
            % requires. Also the object polyshaped is passed.
            
            if obj.image_tp == 0 & nargin == 2 %#ok<AND2>
                P = varargin{1};
                
                proj = obj.transform( P );
            else
                
                proj = obj;
            end
            
            % now I can worrk with proj_pitch
            % the 4 points are 12 - 11
            %                  14 - 13
            % with the reference system below 13 and 11
            A_ = proj.pitch(11);
            F_ = proj.pitch(12);
            A__ = proj.pitch(13);
            F__ = proj.pitch(14);
            
            net.x = [A_.params(1), F_.params(1), F__.params(1), A__.params(1)];
            net.y = [A_.params(2), F_.params(2), F__.params(2), A__.params(2)];
            
            net.poly = polyshape( net.x, net.y);
        end
        
        function pj_pitch = get_projection_pitch( obj, side, height, P )
            
            if side == 0
                % right side
                
            else
                %left side
                p(1,:) = P*[0, 0, 0, 1]';
                p(2,:) = P*[-9,0, 0, 1]';
                p(3,:) = P*[-9,9, 0, 1]';
                p(4,:) = P*[0, 9, 0, 1]';
                
                p(5,:) = P*[0, 0, height, 1]';
                p(6,:) = P*[-9,0, height, 1]';
                p(7,:) = P*[-9,9, height, 1]';
                p(8,:) = P*[0, 9, height, 1]';
            end
            p = p ./ p(:,3);
            pj_pitch.poly = polyshape( p(:, 1), p(:,2) );
            pj_pitch.poly = convhull(pj_pitch.poly );
            pj_pitch.x = pj_pitch.poly.Vertices(:, 1);
            pj_pitch.y = pj_pitch.poly.Vertices(:, 2);
        end
        
        
    end
end