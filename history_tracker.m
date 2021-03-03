classdef history_tracker
    %history_tracker Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_coordinate;
        radii;
        bbox;
        state;
        total_visible_count;
        consecutive_invisible;
        length;
    end
    
    methods
        function obj = history_tracker(varargin)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            if nargin < 2
                obj.image_coordinate{1} = [];
                obj.radii{1} = [];
                obj.bbox{1} = [];
                obj.state{1} = "unknown";
                obj.length = 0;
                obj.total_visible_count = 0;
                obj.consecutive_invisible = 0;
            else
                obj.image_coordinate{1} = varargin{1};
                obj.radii{1} = varargin{2};
                obj.bbox{1} = bbox_from_circle( varargin{1}, varargin{2}, 'std' );
                obj.state{1} = varargin{3};
                obj.length = 1;
                obj.total_visible_count = 1;
                obj.consecutive_invisible = 0;
            end
        end
        
        function obj = add(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if nargin == 1
                obj.image_coordinate{end + 1} = [];
                obj.radii{end + 1} = [];
                obj.bbox{end + 1} = [];
                obj.state{end + 1} = "unknown";
                obj.length = obj.length + 1;
                %unchanged obj.total_visible_count;
                obj.consecutive_invisible = obj.consecutive_invisible +1;
            else
                obj.image_coordinate{end + 1} = varargin{1};
                obj.radii{end + 1} = varargin{2};
                obj.bbox{end + 1} = bbox_from_circle( varargin{1}, varargin{2}, 'std' );
                obj.state{end + 1} = varargin{3};
                obj.length = obj.length + 1;
                if strcmp( varargin{3}, "predicted" )
                    %unchanged obj.total_visible_count;
                    obj.consecutive_invisible = obj.consecutive_invisible +1;
                else
                    obj.total_visible_count = obj.total_visible_count + 1;
                    obj.consecutive_invisible = 0;
                end
            end
        end
        
        
        function obj = discard_last( obj, varargin )
            if ( nargin > 2 & strcmp(varargin{1}, "forced")) | (obj.consecutive_invisible > 6)
                obj.image_coordinate{end} = [];
                obj.bbox{end} = [];
                obj.state{end} = "unknown";
                obj.consecutive_invisible = 1;
            end
        end
        
        
    end
end

