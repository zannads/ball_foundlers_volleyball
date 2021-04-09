function [point3d, ball_start_time] = ball_foundlers_jump_detector( a_h, start_analysis_time, pitch_side )
%BALL_FOUNDLERS_JUMP_DETECTOR Computes the 3d position of the first points
%where the trajectory takes place and the time at which tracking of the
%ball should start.

%% TRACKINIG OF MOST LIKELY OBJECTS
global debug_jump;
if debug_jump
    close all;
    videoPlayer = vision.VideoPlayer('Position',[100,100,680,520]);
    clr = {'blue', 'green', 'red', 'cyan', 'magenta', 'yellow', 'black', 'white'};
    
end

%load the player detector
detector = vision.CascadeObjectDetector('ball_foundler.xml', 'UseROI', true);

% the average number of step needed to detect the jump, the higher the
% number. The longer the time to detect the jump.
average_step_number = 55;

% create the video reader again and start the analysis
video_reader = VideoReader( a_h.get_videoname );
video_reader.CurrentTime = start_analysis_time;
frame = readFrame( video_reader );
detectedImg = frame;

% detect the object that are most likely to be the players doing the
% service.
bbox = detector( frame, pitch_side);

% remove too small boxes
smaller = (bbox(:, 3) < 78) & ((bbox(:,3).*bbox(:,4) < 78*33 ) ) ;
bbox = bbox( ~smaller, :);

% I create the variables to keep track of the possible bboxes
% one tracker for each bbox
tracker = cell( size( bbox, 1), 1);
% history of the centroid of each cluster of points
centroid = cell( length(tracker), average_step_number);
% time of each centroid for sequential ransac
time_steps = zeros(1, average_step_number);
time_steps(1) = start_analysis_time;

%initialize trackers
for jdx = 1:size( bbox, 1)
    objectRegion = bbox(jdx, :);
    
    points = detectMinEigenFeatures(rgb2gray(frame),'ROI',objectRegion);
    %points = detectHarrisFeatures( rgb2gray(frame), 'ROI', objectRegion);
    %         if debug
    %             figure;
    %             detectedImg = insertObjectAnnotation(frame, 'rectangle', bbox, 'p');
    %             imshow(detectedImg); hold on;
    %             plot(points);
    %         end
    tracker{jdx} = vision.PointTracker();
    initialize(tracker{jdx}, points.Location, frame);
    % save centroid
    centroid{jdx, 1} = [ mean(points.Location(:, 1)), mean(points.Location(:, 2))];
end

% continue the analysis
count = 2;
while count <= average_step_number
    
    %next frame
    frame = readFrame(video_reader);
    time_steps(count) = video_reader.CurrentTime;
    
    for jdx = 1:length(tracker)
        % get the new position of each cluster
        [points,validity] = tracker{jdx}( frame );
        % save the centroid
        centroid{jdx, count} = [ mean(points(validity, 1)), mean(points(validity, 2))];
        
        if debug_jump
            frame = insertMarker(frame,points(validity, :),'+', 'Color', clr{jdx});
            frame = insertMarker(frame,centroid{jdx, count},'+', 'Color', clr{6});
        end
    end
    
    if debug_jump
        videoPlayer(frame);
    end
    
    count = count+1;
end

if debug_jump
    figure; imshow(detectedImg ); hold on;
    for jdx = 1:length(tracker)
        c = centroid(jdx, :)';
        c = cell2mat( c );
        plot(c(:, 1), c(:, 2), '+', 'Color', clr{jdx}) ;
    end
end

%% SELECTION
% prune the trackers based on trajectory of centroids.
% logical array for selection
standing_still = ones( length( tracker ), 1 );

% if the maximum distance that the centroid has computed is less then
% this values it has to be considered not a player
max_standing_still_distance = 30;

for jdx = 1:length(tracker)
    c = centroid(jdx, :)';
    c = cell2mat( c );
    c = c - c(1, :);
    distances = sqrt( c(:,1).^2 + c(:,2).^2) ;
    [M, ~] = max( distances );
    
    if M > max_standing_still_distance
        standing_still(jdx) = 0;
    end
    
end
% remove the ones that are not moving
centroid = centroid( ~standing_still, :);
bbox = bbox( ~standing_still, :);

% if we still have problems
if size( centroid, 1) > 1
    
    % remove the closed ones.
    
    % take the one with the biggest bbox
    areas = bbox(:, 3).*bbox(:, 4);
    [~, Midx] = max( areas );
    
    strongest = centroid( Midx, :)';
    strongest = cell2mat( strongest );
    
    % search for the closer ones.
    idx = 1;
    while idx < size( centroid, 1)
        if idx ~= Midx
            % acquire the other
            c = centroid(idx, :)';
            c = cell2mat( c );
            
            % compute average distance between trajectory
            c = c - strongest;
            distances = sqrt( c(:, 1).^2 + c(:, 2).^2 );
            distances = mean( distances );
            
            % if it's inside a circle with radius the distance from the
            % center to the corner
            if distances < sqrt( (bbox(Midx, 3)./2).^2 + (bbox(Midx, 4)./2).^2 )
                %remove it
                centroid( idx, : ) = [];
                bbox( idx, : ) = [];
                % step back because we have eliminated one row
                idx = idx-1;
                % also reduce Midx if I remove a line before it
                if idx < Midx 
                    Midx = Midx-1;
                end
            end
        end
        idx = idx +1;
    end
end

% if we still have problems
if size( centroid, 1) > 1
    
    % remove the one that are not along the direction of play
    easylines = zeros( size( centroid, 1), 2);
    
    % find in a very fast way the line along the movement takes place
    idx = 1;
    while idx <= size( centroid, 1)
        c = centroid(idx, :)';
        c = cell2mat( c );
        [~, easylines(idx, :), ~, ~] = ball_foundlers_functionfit( c(:,1), c(:,2), 'line', 'lsq' );
        
        idx = idx +1;
    end
    
    % get the angle of this line
    easylines = atan( easylines(:, 2)./easylines(:, 1) );
    
    % if it is not along the same direction of play
    % to improve using volleyball pitch get_direction_of_play??
    wrong_oriented = (easylines < 0) | ( easylines > 2 );
    
    
    % remove the ones moving in the wrong direction
    centroid = centroid( ~wrong_oriented, :);
    bbox = bbox( ~wrong_oriented, :);
    
end

if debug_jump
    figure; imshow(detectedImg ); hold on;
    for jdx = 1:size(centroid, 1)
        c = centroid(jdx, :)';
        c = cell2mat( c );
        plot(c(:, 1), c(:, 2), '+', 'Color', clr{jdx}) ;
    end
end


%% SEQUENTIAL RANSAC
% now look for the conic due to the jump
% maybe reducing the set to the center
centroid = centroid(1, :)';
centroid = cell2mat( centroid );
x = centroid( :, 1);
y = centroid( :, 2);

% max_distance for inliers
max_distance = 1e-4;
step = 1;

% search for the highest point (min y) should be the top of the jump
[~, m_idx] = min( y );

% at this time the ball starts
ball_start_time = time_steps(m_idx);

% I can't go lower then 1. Left limit on centroid array
l_idx = min(3, m_idx-1) ;
% I  cant' go over the end of the array
r_idx = min(3, length(x)-m_idx );

conic_inliers = zeros( size(x) );
%first_line_inliers = zeros( size( x) );
%second_line_inliers = zeros( size( x) );
conic_inliers( (m_idx-l_idx) : (m_idx+r_idx) ) = ones( l_idx+r_idx+1, 1);
% make it logic
conic_inliers = conic_inliers > 0;
%first_line_inliers = first_line_inliers > 0;
%second_line_inliers = second_line_inliers > 0;

% extract the point in the set
x_ = x( conic_inliers, : );
y_ = y( conic_inliers, : );

[c_eq, c_par, ~, ~] = ball_foundlers_functionfit( x_, y_, 'conic', 'lsq');

while step
    update = 0;
    % move to the left toward 1
    l_idx = l_idx + 1;
    % I can't go lower then 1. Left limit on centroid array
    if l_idx <= m_idx-1
        % take the new point
        p1 = [x(m_idx-l_idx), y(m_idx-l_idx) ];
        % check if is quite closed
        distances = evalconic( c_par, p1);
        if distances < max_distance
            % ok it is.
            conic_inliers( m_idx-l_idx ) = 1;
            update = 1;
        end
    end
    
    % move to the right toward end
    r_idx = r_idx + 1;
    % I  cant' go over the end of the array
    if r_idx <= length(x)-m_idx
        % take the new point
        p2 = [x(m_idx+r_idx), y(m_idx+r_idx) ];
        % check if is quite closed
        distances = evalconic( c_par, p2);
        if distances < max_distance
            % ok it is.
            conic_inliers( m_idx+r_idx ) = 1;
            update = 1;
        end
    end
    
    if update
        % extract the point in the set
        x_ = x( conic_inliers );
        y_ = y( conic_inliers );
        
        % update the conic
        [eq, params, ~, inlier_idx] = ball_foundlers_functionfit( x_, y_, 'conic', 'ransac', 'MaxDistance', max_distance/5 );
    end
    
    % check how many of them are inlier of the new model
    if ~update || (sum(inlier_idx) < (length(inlier_idx)-2))
        % more then 2 points are outliers.
        % stop the count
        step = 0;
    else
        % they are almost all inliers , keep searching.
        % update the model
        c_eq = eq;
        c_par = params;
        
        % check if p1 or p2 were discarded, in case test them again on the
        % new model
        if conic_inliers( m_idx-l_idx ) == 0
            % it was discarded
            distances = evalconic( c_par, p1);
            if distances < max_distance
                % ok reinsert
                conic_inliers( m_idx-l_idx ) = 1;
            end
        end
        % same for p2
        if conic_inliers( m_idx+r_idx ) == 0
            % it was discarded
            distances = evalconic( c_par, p2);
            if distances < max_distance
                % ok reinsert
                conic_inliers( m_idx+r_idx ) = 1;
            end
        end
    end
    
    if debug_jump
        if conic_inliers( m_idx+r_idx ) == 0
            plot(p2(1), p2(2), '*r');
        else
            plot(p2(1), p2(2), '*g');
        end
        if conic_inliers( m_idx-l_idx ) == 0
            plot(p1(1), p1(2), '*r');
        else
            plot(p1(1), p1(2), '*g');
        end
        
        range2d = [min( x ), max( x ),...
            1, 720];
        fimplicit( c_eq, range2d );
    end
end
% separate the set in 3 if possible and look for the two lines

first_line_inliers = ~conic_inliers;
idx = length(first_line_inliers);
c = 0;
while idx>0 
    if first_line_inliers(idx) == 1
        first_line_inliers(idx) = 0;
    else
        c = c+1;
        if c>2
            idx = 0;
        end
    end
    
    idx = idx-1;
end
        
second_line_inliers = ~(conic_inliers | first_line_inliers);

% build the points
if debug_jump
    conic_points = [x(conic_inliers), y(conic_inliers) ];
end
fl_points = [x(first_line_inliers), y(first_line_inliers) ];
sl_points = [x(second_line_inliers), y(second_line_inliers) ];

[~, fl_par, ~, fl_inlier] = ball_foundlers_functionfit( fl_points(:,1), fl_points(:,2),...
    'line', 'ransac', 'MaxDistance', 20 );
[~, sl_par, ~, sl_inlier] = ball_foundlers_functionfit( sl_points(:,1), sl_points(:,2),...
    'line', 'ransac', 'MaxDistance', 20 );

if debug_jump 
    % draw the lines
    x_ = fl_points(fl_inlier, 1);
    x_ = [min(x_) max(x_)];
    y_ = (-fl_par(1).*x_ -1)/fl_par(2);
    plot(x_, y_, 'g-')
  
    x_ = sl_points(sl_inlier, 1);
    x_ = [min(x_) max(x_)];
    y_ = (-sl_par(1).*x_ -1)/sl_par(2);
    plot(x_, y_, 'g-')
end

    %% get two points
    % intersection between conic and the two lines. 
    syms u v real;
    
    %line1
    eqns = [[c_par;1]'*[u^2; u*v; v^2; u; v; 1] == 0, [fl_par',1]*[u; v; 1] == 0 ]; 
    [p1u, p1v] = solve( eqns, [u,v] );
    p1 = [double( p1u ), double( p1v )];
    
    % find which of the two solution is the one I'm looking for
    % get the leftmost point for line 1
    x_ = min( fl_points(fl_inlier, 1) );
    y_ = (-fl_par(1).*x_ -1)/fl_par(2);
    
    % look which of the two solution is closer
    distances = p1 - [x_, y_];
    distances = distances(:, 1).^2 + distances(:, 2).^2;
    [~, m_idx] = min(distances);
    
    if debug_jump
        plot(p1(:,1), p1(:,2), 'm*');
        plot(p1(m_idx,1), p1(m_idx,2), 'w*', 'MarkerSize', 3 );
    end
    
    % sometimes, the conic doesn't intersect with the lines. In this case
    % neglect the intersection and take the closest point from the lines. 
    if isempty( p1 )
        p1 = [x_, y_];
    else
        % they intersect
        p1 = p1(m_idx, :);
    end
    
    % line2
    eqns = [[c_par;1]'*[u^2; u*v; v^2; u; v; 1] == 0, [sl_par',1]*[u; v; 1] == 0 ]; 
    [p2u, p2v] = solve( eqns, [u,v] );
    p2 = [double( p2u ), double( p2v )];
    
    % find which of the two solution is the one I'm looking for
    % get the rightmost point for line 2
    x_ = min( sl_points(sl_inlier, 1) );
    y_ = (-sl_par(1).*x_ -1)/sl_par(2);
    
    % look which of the two solution is closer
    distances = p2 - [x_, y_];
    distances = distances(:, 1).^2 + distances(:, 2).^2;
    [~, m_idx] = min(distances);
    
    if debug_jump
        plot(p2(:,1), p2(:,2), 'm*');
        plot(p2(m_idx,1), p2(m_idx,2), 'w*', 'MarkerSize', 3 );
    end
    
    % sometimes, the conic doesn't intersect with the lines. In this case
    % neglect the intersection and take the closest point from the lines. 
    if isempty( p2 )
        p2 = [x_, y_];
    else
        % they intersect
        p2 = p2(m_idx, :);
    end
    
       
    %% 3d move
    %Jump line -> conic
    jump_s_pos3d = point3d_from_2d( p1(1), ...
        p1(2), ...
        a_h.get_P, 'z', 0.9);
    %Land conic -> line
    jump_e_pos3d = point3d_from_2d( p2(1), ...
        p2(2), ...
        a_h.get_P, 'z', 0.9);
    
    %Take the coordinate between jump and landing of the player.
    point3d.x = (jump_s_pos3d.x + jump_e_pos3d.x )/2;
    point3d.y = (jump_s_pos3d.y + jump_e_pos3d.y )/2;
    point3d.z = (jump_s_pos3d.z + jump_e_pos3d.z )/2;
    
