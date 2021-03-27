function set = remove_static_harrisfeatures( set )
%REMOVE_STATIC_HARRISFEATURES Given a set of cornerpoints it removes from
%this set all the cornerpoints that are common betwen this set.

% get how many set of cornerpoints we have to check
n_set = length( set );

% max distance to consider two points as the same
max_distance_merge = 3;
% min number of matches to define a point as static
min_matches = (n_set-1)*2/3;

% look for the smaller set
min_idx = 0;
min_quantity = Inf;
for idx = 1:n_set 
    if length(set{idx}) < min_quantity
        min_idx = idx;
        min_quantity = length(set{idx});
    end
end

% now start to remove 
% for every point of the smallest set 
% count how many times it appears in the others. 
% if this number is greater then a threeshold then remove it from all the
% sets 

smallest_set = set{min_idx};
% I store the matches betweeen the idx point (row) wrt the set (column)
% the value is 0 if there is no match. the index in the set if there is a
% match
merger = zeros( length( smallest_set ), n_set );
for idx = 1:length( smallest_set )
    point = smallest_set( idx ).Location;
     
    % start comparison with other points
    for jdx = 1:n_set 
        % avoid comparing with itself
        if jdx ~= min_idx
            % get closest point from another set
            temp_set = set{jdx};
            distances = temp_set.Location;
            distances = distances - point;
            distances = sqrt( distances(:, 1).^2 + distances(:, 2).^2 );
            
            [m, mdx] = min(distances);
            
            if m <= max_distance_merge
                merger( idx, jdx ) = mdx;
            end
        end
    end
    
    
end

% extract for every point how many matches it has.
static_points = sum( merger > 0, 2) >= min_matches;
tobe_removed = merger( static_points, :);

% remove on the smallest set
set{min_idx} = smallest_set( ~static_points );

% remove on the other sets. 
for jdx = 1:n_set 
        % avoid comparing with itself
        if jdx ~= min_idx
            temp_set = set{jdx};
            
            removed = 0;
            for idx = 1:size( tobe_removed, 1)
                % get the idx of the point to remove and asjust it with the
                % ones that have already been removed
                temp_position = tobe_removed(idx, jdx ) - removed;
                % check validity
                if temp_position > 0 && temp_position <= size( temp_set, 1)
                    % remove it
                    temp_set( temp_position ) = [];
                    removed = removed +1;
                end
            end
            % reassign
            set{jdx} = temp_set;
        end     
end