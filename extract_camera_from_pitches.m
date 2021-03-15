function [P, R, K, O] = extract_camera_from_pitches( image_pitch ,real_pitch)
%EXTRACT_CAMERA_FROM_PITCHES Extract all the params of a camera
%   Starting from an image of a pitch object and the real world object extracts
%   the parameterss of the camera

% format points for next algorithm
% count how many points we have (at least 6)
available_points = 0;
for idx = 1:14
    if( image_pitch.pitch(idx).is_valid() )
        available_points = available_points +1;
    end
end

if( available_points  >= 6 )
    % ok I can procced with dlt algorithm
    
    %pre allocate per speed
    image_points = zeros(available_points, 2);
    pitch_coordinates = zeros(available_points, 3);
    %save them into the arrays
    jdx = 1;
    for idx = 1:14
        if( image_pitch.pitch(idx).is_valid() )
            image_points(jdx, :) = image_pitch.pitch(idx).params(1:2)';
            pitch_coordinates(jdx, :) = real_pitch.pitch(idx).params';
            jdx = jdx+1;
        end
    end
    
    
    % use DLT algorithm to get the projection matrix
    P = estimateCameraMatrix( image_points, pitch_coordinates );
    % the representation of points is inverted in matlab
    P = P';
    
    M = P(:, 1:3);
    m = P(:, end);
    
    % obtain rotation and calibration of camera
    [R, K] = qr( M' );
    %camera centre
    O = -M\m;
else
    % unfortunate case I don't have wnough points
    P = zeros(3,4);
    R = zeros(3);
    K = R;
    O = zeros(3,1);
    
end
end

