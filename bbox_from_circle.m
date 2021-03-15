function bbox = bbox_from_circle( center, radii, style, varargin )
%BBOX_FROM_CIRCLE Compute the bbox surrounding a cricle given its center
%and radius.

% since bbox can both go outside or stay inside it may be useful to let
% them inside the image
%% limits
if nargin == 5 & strcmp( varargin{1}, "Limits" )
    % if I have alimit on where bboxes can be
    limits = varargin{2};
    x_1 = max( floor( center(1) -radii ), 1 );        % leftmost point
    y_1 = max( floor( center(2) -radii ), 1 );        % leftmost point
    x_2 = min( floor( center(1) +radii ), limits(2) );        % rightmost point
    y_2 = min( floor( center(2) +radii ), limits(1) );        % rightmost point
else
    % if I don't have any limits and for example ball is half outside the
    % image
    x_1 = floor( center(1) -radii );        % leftmost point
    y_1 = floor( center(2) -radii );        % leftmost point
    x_2 = floor( center(1) +radii );        % rightmost point
    y_2 = floor( center(2) +radii );        % rightmost point
end

%% format
% based on what I need the bbox: drawing it or using it to extrcat a region
% from an image I need a different definition.

if strcmp( style, "std" )
    % If I have to print it [x, y, width, height]
    bbox = [x_1, y_1, x_2-x_1, y_2-y_1];
    
elseif strcmp( style, "vectorial" )
    % If I have to extract an area of an image [starting idx of array y :
    % starting idx of array y, same for x]
    bbox = [y_1, y_2, x_1, x_2];
else
    % std it is 
    bbox = [x_1, y_1, x_2-x_1, y_2-y_1];
end
end