classdef volleyball_pitch
    %VOLLEYBALL_PITCH Class to save the parameters of a volleyball pitch
    %   A pitch can be real, then classic position are inserted, otherwise
    %   if it's on the image use the add_point method
    
    properties
        pitch
        f_h
        real_img
    end
    
    methods
        function obj = volleyball_pitch( varargin )
            %VOLLEYBALL_PITCH Construct an instance of this class
            %   We have from A to J on the pitch 
            % A' and F' top of the net
            % A'' and F'' bottom of the net
            % If is real don't insert anything, otherwise insert something
            % just to know

            %net_height = 2.24; %m %femminile
            net_height = 2.43; %m
          
            obj.pitch(1) = abs_point([0, 0, 0], 'A');
            obj.pitch(2) = abs_point([3, 0, 0], 'B');
            obj.pitch(3) = abs_point([9, 0, 0], 'C');
            obj.pitch(4) = abs_point([9, 9, 0], 'D');
            obj.pitch(5) = abs_point([3, 9, 0], 'E');
            obj.pitch(6) = abs_point([0, 9, 0], 'F');
            obj.pitch(7) = abs_point([-3, 9, 0], 'G');
            obj.pitch(8) = abs_point([-9, 9, 0], 'H');
            obj.pitch(9) = abs_point([-9, 0, 0], 'I');
            obj.pitch(10) = abs_point([-3, 0, 0], 'J');
            obj.pitch(11) = abs_point([0, 0, net_height], 'A_');
            obj.pitch(12) = abs_point([0, 9, net_height], 'F_');
            obj.pitch(13) = abs_point([0, 0, net_height], 'A__');
            obj.pitch(14) = abs_point([0, 9, net_height], 'F__');
            
            if nargin >1
                obj.real_img = 1;
            else 
                obj.real_img = 0;
            end
        end
        
        function  draw(obj,inputArg)
            %DRAW Draw the pitch
            %   Detailed explanation goes here
            
            
        end
        
        function  add_point(obj,inputArg)
            %ADD_POINT give new coordinates for a pitch only for image
            %pitch
            %   Detailed explanation goes here
            
        end
        
    end
end

