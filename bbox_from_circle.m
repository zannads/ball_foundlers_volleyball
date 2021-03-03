function bbox = bbox_from_circle( center, radii, style, varargin )

if nargin == 5 & strcmp( varargin{1}, "Limits" )
    limits = varargin{2};
    x_1 = max( floor( center(1) -radii ), 1 );        % leftmost point
    y_1 = max( floor( center(2) -radii ), 1 );        % leftmost point
    x_2 = min( floor( center(1) +radii ), limits(2) );        % rightmost point
    y_2 = min( floor( center(2) +radii ), limits(1) );        % rightmost point
else
    x_1 = floor( center(1) -radii );        % leftmost point
    y_1 = floor( center(2) -radii );        % leftmost point
    x_2 = floor( center(1) +radii );        % rightmost point
    y_2 = floor( center(2) +radii );        % rightmost point
end

if strcmp( style, "std" )
    bbox = [x_1, y_1, x_2-x_1, y_2-y_1];
elseif strcmp( style, "vectorial" )
    bbox = [y_1, y_2, x_1, x_2];
else
    bbox = [x_1, y_1, x_2-x_1, y_2-y_1];
end
end