function point3d = ball_foundlers_hitdetection(a_h, ball, info )
%BALL_FOUNDLERS_HITDETECTION

global debug_hitdetection;

mem = length( info );
p_ = cell(mem, 1);
for idx = 1:mem
    p_{idx} = detectHarrisFeatures( rgb2gray( info(idx).frames ) );
end

if debug_hitdetection
    p = ball.last_known;
    
    r = floor( sqrt(mem) );
    centroid = ceil(mem/r);
    
    figure;
    for idx = 1:mem
        subplot(r, centroid, idx);
        imshow( info(idx).frames); hold on;
        plot( p(1), p(2), 'or');
        plot( p_{idx} );
    end
    
    figure;
    for idx = 1:mem
        subplot(r, centroid, idx);
        imshow( info(idx).reports.foreground.mask); hold on;
        plot( p(1), p(2), 'or');
    end
    
    figure;
    for idx = 1:mem
        subplot(r, centroid, idx);
        imshow( info(idx).reports.stepper.mask); hold on;
        plot( p(1), p(2), 'or');
    end
    
end


% proviamo con remove statics
p_ = remove_static_harrisfeatures( p_ );
p__ = p_{1};

%     real_p = volleyball_pitch;
%     side = real_p.get_projection_pitch( side, 2.5, a_h.get_P );
%     on_side = inpolygon( p__.Location(:,1), p__.Location(:,2), side.x, side.y );
%     p__ = p__(on_side, :);

stats = regionprops('struct', info(6).reports.stepper.mask ,'Area', 'BoundingBox', 'Centroid',...
    'Circularity', 'MajorAxisLength', 'MinorAxisLength', 'Orientation' );

% prune bboxes
areas = extractfield_( stats, 'Area');
stats = stats( areas>1000 & areas < 15000);

% delete insiginficant points
p__ = select_roi_harrisfeatures( p__, extractfield_( stats, 'BoundingBox') );


tr = ball.get_known_positions;
[treq, ~, tr_C, ~] = ball_foundlers_functionfit( tr(:,1), tr(:,2), 'conic', 'lsq');

centroid = zeros( length( p__ ), 2);
distance = zeros( length( p__ ), 1);

for idx = 1:length( p__ )
    centroid(idx, 1:2) = [mean( p__{idx}.Location(:,1) ), mean( p__{idx}.Location(:,2) )];
    distance(idx) = [centroid(idx,1), centroid(idx,2), 1]*tr_C*[centroid(idx,1), centroid(idx,2), 1]';
end

[~, midx] = min(abs(distance));

if debug_hitdetection
    ff = insertObjectAnnotation( info(1).frames, 'rectangle', extractfield_( stats, 'BoundingBox'), ...
        'f');
    figure; imshow( ff ); hold on;
    fimplicit( treq, [1, 1280, 1, 720] );
    for idx = 1:length( p__ )
        plot( p__{idx} );
        plot( centroid(idx, 1), centroid(idx, 2), '*r' );
    end
    hold on;
    plot( centroid(midx, 1), centroid(midx, 2), '*k', 'MarkerSize', 5);
end

player = centroid( midx, :);

point3d = point3d_from_2d( player(1), player(2), a_h.get_P, 'z', 0.7 );
end