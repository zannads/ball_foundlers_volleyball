classdef history_tracker
    %history_tracker Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_coordinate;
        %hsv_scale;
        bbox;
        state;
        total_visible_count;
        consecutive_invisible;
        length;
    end
    
    methods
        function obj = history_tracker()
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.image_coordinate{1} = [];
            obj.bbox{1} = [];
            obj.state{1} = "unknown";
            obj.length = 0;
            obj.total_visible_count = 0;
            obj.consecutive_invisible = 0;
        end
        
        function obj = add(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if nargin == 1
                obj.image_coordinate{end + 1} = [];
                obj.bbox{end + 1} = [];
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
        
        function obj = predict_location( obj , frame )
            % se il precedente è unknown
            % chiedi punt
            if strcmp ( obj.state{end} , "unknown" )
                %acquire pts from image
                % set to known
                % length = +1
                figure; imshow(frame);
                [x, y ]= getpts();
                x = ceil( x) ;
                y = ceil(y);
                
                obj.bbox{end} = [x(1), y(1), (x(2)-x(1)), (y(2)-y(1))];
                obj.image_coordinate{end} = [ ((x(1)+x(2))/2),  ((y(1)+y(2))/2)];
                obj.state{end} = "known";
                obj.length = obj.length +1;
                obj.total_visible_count = obj.total_visible_count + 1;
                %reset
                obj.consecutive_invisible = 0;
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
                obj.image_coordinate{end+1} = obj.image_coordinate{end};
                obj.state{end+1} = "predicted";
                obj.length = obj.length+1;
                % unchanged obj.total_visible_count
                obj.consecutive_invisible = obj.consecutive_invisible + 1;
                return;
            end
            
            
            % altrimenti
            %liinear interp
            
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
            
            obj.bbox{end+1} = [new_top, new_area] ;
            obj.state{end+1} = "predicted";
            obj.length = obj.length + 1;
            % unchanged obj.total_visible_count
            obj.consecutive_invisible = obj.consecutive_invisible + 1;
        end
        
        function obj = assignment(  obj, varargin )
            if strcmp( obj.state{end}, "known" )
                return;
            end
            %If i decide that the prevision is correct, I need to increase
            %total visible count and set to 0 consecutive invisible
            
            % the thing I trust more is my prediction, so I check on the
            % prediction bbox if there is any non zero in the masks
            if strcmp( obj.state{end}, "predicted" )
                bbox_prediction = obj.bbox{end};
                y_1 = bbox_prediction(1, 2);
                x_1 = bbox_prediction(1, 1);
                y_2 = y_1 + bbox_prediction(1, 4)-1;
                x_2 = x_1 + bbox_prediction(1, 3)-1;
                
                % let's start that I know the order of the 3 mask
                if ~isempty( varargin{1} )
                    mask_ = varargin{1}(y_1:y_2, x_1:x_2 );
                    f_grade = sum(mask_, 'all') / (bbox_prediction(3)*bbox_prediction(4) );
                end
                if ~isempty( varargin{2} )
                    mask_ = varargin{2}(y_1:y_2, x_1:x_2 );
                    hsv_grade = sum(mask_, 'all') / (bbox_prediction(3)*bbox_prediction(4) );
                end
                if ~isempty( varargin{3} )
                    mask_ = varargin{3}(y_1:y_2, x_1:x_2 );
                    s_grade = sum(mask_, 'all') / (bbox_prediction(3)*bbox_prediction(4) );
                end
                %             frame = varargin{4};
                %             test with harris feauture
                %             figure; imshow(frame(y_1:y_2, x_1:x_2 ));
                %             a = detectHarrisFeatures(rgb2gray(frame(y_1:y_2, x_1:x_2, : )));
                %             hold on; plot(a);
                %
                % now use grades to validate it
                % if it is enough save it to known
                if (f_grade > 0.3 | hsv_grade > 0.3 | s_grade > 0.3)  %#ok<OR2>
                    % update the bbox
                    obj.bbox{end} = bbox_prediction(idx, :);
                    obj.image_coordinate{end} = [ (x_1+x_2)/2, (y_1+y_2)/2 ];
                    obj.state{end} = "known";
                    obj.total_visible_count = obj.total_visible_count +1;
                    obj.consecutive_invisible = 0;
                    return;
                end
            end
            % if I haven't svaed my prediction, let's look at the proposed
            % bboxes
            max_ = [0, 0];
            bbox_prediction = varargin{5};
            for idx = 1:size( bbox_prediction, 1)
                y_1 = bbox_prediction(idx, 2);
                x_1 = bbox_prediction(idx, 1);
                y_2 = y_1 + bbox_prediction(idx, 4)-1;
                x_2 = x_1 + bbox_prediction(idx, 3)-1;
                
                % let's start that I know the order of the 3 mask
                % I don't need f_mask anymore
                if ~isempty( varargin{2} )
                    mask_ = varargin{2}(y_1:y_2, x_1:x_2 );
                    hsv_grade = sum(~mask_, 'all') / (bbox_prediction(3)*bbox_prediction(4) );
                end
                if ~isempty( varargin{3} )
                    mask_ = varargin{3}(y_1:y_2, x_1:x_2 );
                    s_grade = sum(~mask_, 'all') / (bbox_prediction(3)*bbox_prediction(4) );
                end
                distance = norm( obj.image_coordinate{end-1}- [ (x_1+x_2)/2, (y_1+y_2)/2 ] );
                area_increase = obj.bboxes{end-1};
                area_increase = area_increase(3)*area_increase(4)/  (bbox_prediction(3)*bbox_prediction(4) );
                %             frame = varargin{4};
                %             test with harris feauture
                %             figure; imshow(frame(y_1:y_2, x_1:x_2 ));
                %             a = detectHarrisFeatures(rgb2gray(frame(y_1:y_2, x_1:x_2, : )));
                %             hold on; plot(a);
                %
                % now use grades to validate it (object function to tune
                
                grade =  0.1*hsv_grade + 0.01*distance ; % + distance from last
                if grade > max_(2)
                    max_(1) = idx;
                    max_(2) = grade;
                end
                
            end
            
            if max_(1) == 0 | max_(2) < 0.3
                % no one has passed the test discard prediction if total
                % invisible less then param setted in class
                obj = obj.discard_last();
                return;
            else
                % save
                obj.bbox{end} = bbox_prediction(idx, :);
                obj.image_coordinate{end} = [ (x_1+x_2)/2, (y_1+y_2)/2 ];
                obj.state{end} = "known";
                obj.total_visible_count = obj.total_visible_count +1;
                obj.consecutive_invisible = 0;
                return;
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
    end
end

