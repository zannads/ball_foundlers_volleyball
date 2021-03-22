function lin_param = conicfit( p )
%CONICFIT Given a set of points at least 5: it returns the parameter of the
%conic satisfing least square if the point are more the then 5 or the conic
%passing through the 5 points.

[rp, cp] = size( p );

%check dimensions.
if (rp < 5 & cp < 5) | (rp >= 5 & cp <2 ) | (rp <2 & cp >= 5) %#ok<AND2,OR2>
    lin_param = [];
    return;
end

% verticalize arrays
if rp < cp
    p = p';
end

% separete infos
x = p(:, 1);
y = p(:, 2);

% find the conic. the operator \ performes least square when dimensions
% don't match. 
A = [ x.^2, x.*y, y.^2, x, y] ;
lin_param = A\( -1*ones( size( x, 1), 1 ) );
end