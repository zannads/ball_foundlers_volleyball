function [point_1, point_2] = ball_foundlers_extract_points( data, type )
%BALL_FOUNDLERS_EXTRACT_POINTS Select the useful informations from the structure
%where they are placed.
% Since data struct is full of info I need to extrcat the two key
% informations.
% The two points belongin to the vertical plane where the 3d action takes
% place.
% All the points of the tracking from the start to the end of the service.

%% plane points
if strcmp( type, 'plane')
    %% start
    % on the hand, linear interpolation like in jump, I know z = 0 because
    % is a foot.
    %Jump
    jump_s_pos3d = point3d_from_2d( data.manual.jump_s_pos(1), ...
        data.manual.jump_s_pos(2), ...
        data.P, 'z', 0);
    %Land
    jump_e_pos3d = point3d_from_2d( data.manual.jump_e_pos(1), ...
        data.manual.jump_e_pos(2), ...
        data.P, 'z', 0);
    
    %Take the coordinate between jump and landing of the player.
    point_1.x = (jump_s_pos3d.x + jump_e_pos3d.x )/2;
    point_1.y = (jump_s_pos3d.y + jump_e_pos3d.y )/2;
    point_1.z = (jump_s_pos3d.z + jump_e_pos3d.z )/2;
    
    %% end
    if data.manual.ball_e_mode == 1
        % ball touches the net!
        
        % search for the last point, it is at ball_e_time
        idx = 1;
        found = 0;
        while idx < size(data.detected.frame, 1) & ~found
            if data.detected.frame{idx} > data.manual.ball_e_time
                last_point = data.detected.position{idx};
                if ~isempty( last_point )
                    found = ~found;
                end
            end
            idx = idx+1;
        end
        % plot it 
        plot( last_point(1), last_point(2), 'og', 'MarkerSize', 5);
        
        %it's on the net, thus on the coordinate x = 0;
        point_2 = point3d_from_2d( last_point(1), last_point(2), data.P, 'x', 0);
        
        
    elseif data.manual.ball_e_mode == 2
        % ball is on the floor! 
        
        % search for the last point, it is at ball_e_time
        idx = 1;
        found = 0;
        while idx < size(data.detected.frame, 1) & ~found
            if data.detected.frame{idx} > data.manual.ball_e_time
                last_point = data.detected.position{idx};
                if ~isempty( last_point )
                    found = ~found;
                end
            end
            idx = idx+1;
        end
        plot( last_point(1), last_point(2), 'og', 'MarkerSize', 5);
        
        %it's on the floor, thus on the coordinate z = 0;
        point_2 = point3d_from_2d( last_point(1), last_point(2), data.P, 'z', 0);
        
        
    else
        % ball ends on the hands 
        
        % linear interpolation like in start section
        rec_s_pos3d = point3d_from_2d( data.manual.rec_s_pos(1), ...
            data.manual.rec_s_pos(2), ...
            data.P, 'z', 0);
        
        rec_e_pos3d = point3d_from_2d( data.manual.rec_e_pos(1), ...
            data.manual.rec_e_pos(2), ...
            data.P, 'z', 0);
        
        point_2.x = (rec_s_pos3d.x + rec_e_pos3d.x )/2;
        point_2.y = (rec_s_pos3d.y + rec_e_pos3d.y )/2;
        point_2.z = (rec_s_pos3d.z + rec_e_pos3d.z )/2;
    end
        
else
%% conic points
    num_points = size(data.detected.frame, 1);
    
    jdx = 1;
    % I save tracks from data between the tracking times
    
    for idx = 1:num_points
        x_y = data.detected.position{idx};
        if ~isempty( x_y )
            if data.detected.frame{idx} > data.manual.ball_s_time & data.detected.frame{idx} < data.manual.ball_e_time
                point_1(jdx, 1) = data.detected.position{idx}(1); %#ok<AGROW>
                % too busy to preallocate, fuck it.
                point_2(jdx, 1) = data.detected.position{idx}(2); %#ok<AGROW>
                jdx = jdx+1;
            end
        end
    end
    
end

end
