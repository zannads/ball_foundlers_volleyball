function ball = ball_foundlers_convert2dto3d( ball, P, range3d )
%BALL_FOUNDLERS_CONVERT2DTO3D Transform the tracking of a ball from the 2d
%world to the 3d world
global debug_conversion;


% extract from the manually inserted info of the action all the points of
% the tracking useful to fit the conic.
p = ball.get_known_positions;

% fit the conic on the plane
[ball.C_eq, ball.C_linparam, ball.C_C, ~] = ...
    ball_foundlers_functionfit( p(:, 1), p(:,2), 'conic', 'lsq' );

range2d = [min( p(1, 1), p(end, 1) ), max( p(1, 1), p(end, 1) ),...
    1, 720];

if debug_conversion
    % plot the conic over the 2d image
    hold on;
    fimplicit( ball.C_eq, range2d );
end

% compute the cone where the conic lies
Q = P'*ball.C_C*P;
Q_lin = [Q(1, 1), 2*Q(1, 2), 2*Q(1, 3), 2*Q(1, 4),...
    Q(2, 2), 2*Q(2, 3), 2*Q(2, 4),...
    Q(3, 3), 2*Q(3, 4),...
    Q(4, 4)];
ball.Q_Q = Q;
ball.Q_lin = Q_lin;
ball.Q_eq = @(x,y,z) Q_lin(1).*x.^2 + Q_lin(2).*x.*y + Q_lin(3).*x.*z + Q_lin(4).*x ...
        + Q_lin(5).*y.^2 + Q_lin(6).*y.*z + Q_lin(7).*y ...
        + Q_lin(8).*z.^2 + Q_lin(9).*z ...
        + Q_lin(10);

if debug_conversion
    % create and draw a standard volleyball pitch
    pitch = volleyball_pitch();
    pitch.draw();
end

%%
if debug_conversion
    % plote the cone
    fimplicit3( ball.Q_eq, range3d)
end

% extract vertical plane from the two points.
point_1 = ball.get_point( 1 );
point_2 = ball.get_point( 2 );

p_1 = [point_1.x, point_1.y, point_1.z, 1];
p_2 = [point_2.x, point_2.y, point_2.z, 1];
p_3 = [point_1.x, point_1.y, point_2.z, 1];
p_4 = [point_2.x, point_2.y, point_1.z, 1];

plane = null( [p_1; p_2; p_3; p_4 ] );
ball.P_P = plane;
ball.P_eq = @(x,y,z) plane(1).*x + plane(2).*y + plane(3).*z + plane(4);

if debug_conversion
    % plot the plane
    fimplicit3(ball.P_eq, range3d)
end

%% get the 3d points
%define input grid
[x, y, z] = meshgrid( linspace( range3d(1), range3d(2) ), ...
    linspace( range3d(3), range3d(4) ), ...
    linspace( range3d(5), range3d(6) ) );
% compute implicity defined function
f1 =  Q_lin(1).*x.^2 + Q_lin(2).*x.*y + Q_lin(3).*x.*z + Q_lin(4).*x ...
    + Q_lin(5).*y.^2 + Q_lin(6).*y.*z + Q_lin(7).*y ...
    + Q_lin(8).*z.^2 + Q_lin(9).*z ...
    + Q_lin(10);
f2 = plane(1).*x + plane(2).*y + plane(3).*z + plane(4);

% compute y of the plane starting from x and z
[x2, z2] = meshgrid( linspace( range3d(1), range3d(2) ), ...
    linspace( range3d(5), range3d(6) ) );
y2 = - (plane(1).*x2 + plane(3).*z2 + plane(4)) / plane(2);

if debug_conversion
    % visualize surfaces
    %figure;
    patch( isosurface(x, y, z, f1, 0), 'FaceColor', [0.5 1.0 0.5], 'EdgeColor', 'none');
    patch( isosurface(x, y, z, f2, 0), 'FaceColor', [1.0 0.5 0.0], 'EdgeColor', 'none');
    view(3); camlight; axis vis3d;
end

% Find the difference field.
f3 = f1 - f2;
% Interpolate the difference field on the explicitly defined surface.
f3s = interp3(x, y, z, f3, x2, y2, z2);
% Find the contour where the difference (on the surface) is zero.
C_ = contours(x2, y2, f3s, [0 0]);
% Extract the x- and y- locations from the contour matrix C.
xL = C_(1, 2:end);
yL = C_(2, 2:end);
% same for z_
C_ = contours(x2, z2, f3s, [0 0]);
zL =  C_(2, 2:end);
% Visualize the line.
minz = min( point_1.z, point_2.z );
xL = xL( zL>= minz );
yL = yL( zL>= minz );
zL = zL( zL>= minz );

if debug_conversion
    line(xL,yL,zL,'Color','k','LineWidth',3);
end

ball.trajectory3d.x = xL;
ball.trajectory3d.y = yL;
ball.trajectory3d.z = zL;
end