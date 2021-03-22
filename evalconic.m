function out = evalconic(model, points)

A = [ points(:,1).^2, points(:,1).*points(:,2), points(:,2).^2, ...
            points(:,1), points(:,2), ones( size(points, 1), 1) ];
model = [model; 1];
p = A*model;

out = abs(sum( p, 2));
end