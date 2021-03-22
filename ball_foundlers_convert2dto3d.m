function ball_foundlers_convert2dto3d( data, start_frame )
%BALL_FOUNDLERS_CONVERT2DTO3D Transform the tracking of a ball from the 2d
%world to the 3d world

% check data are correct
if isempty( data.detected )
    return;
end

% show in 2d the trajectory of the ball.
ball_foundlers_show( data, '2d', 'background', start_frame );

% extract from the manually inserted info of the action the two points to
% extarct the plane.
[point_1, point_2] = ball_foundlers_extract_points( data, 'plane' );

% extract from the manually inserted info of the action all the points of
% the tracking useful to fit the conic.
[x_, y_] = ball_foundlers_extract_points( data, 'conic' );

% fit the conic on the plane
A = [ x_.^2, x_.*y_, y_.^2, x_, y_] ;
params = A\( -1*ones( size( x_, 1), 1 ) );
a = params(1);
b = params(2);
c = params(3);
d = params(4);
e = params(5);
C = [ a,    b/2, d/2;
    b/2,  c,   e/2;
    d/2,  e/2, 1];
% plot the conic over the 2d image
hold on;
eq = @(x ,y ) a.*x.^2 + b.*x.*y + c.*y.^2 + d.*x +e.*y + 1 ;
range2d = [min( x_(1), x_(end) ), max( x_(1), x_(end) ),...
    1, 720];
fimplicit( eq, range2d );

% acquire the projection matrix from calibration
P = data.P;

% compute the cone where the conic lies
Q = P'*C*P;
Q_lin = [Q(1, 1), 2*Q(1, 2), 2*Q(1, 3), 2*Q(1, 4),...
    Q(2, 2), 2*Q(2, 3), 2*Q(2, 4),...
    Q(3, 3), 2*Q(3, 4),...
    Q(4, 4)];

% create and draw a standard volleyball pitch
pitch = volleyball_pitch();
pitch.draw();

range3d = data.range;
% % plote the cone
% f = @(x,y,z) Q_lin(1).*x.^2 + Q_lin(2).*x.*y + Q_lin(3).*x.*z + Q_lin(4).*x ...
%     + Q_lin(5).*y.^2 + Q_lin(6).*y.*z + Q_lin(7).*y ...
%     + Q_lin(8).*z.^2 + Q_lin(9).*z ...
%     + Q_lin(10);
% fimplicit3(f,range3d)


% extract vertical plane from the two points.
p_1 = [point_1.x, point_1.y, point_1.z, 1];
p_2 = [point_2.x, point_2.y, point_2.z, 1];
p_3 = [point_1.x, point_1.y, point_2.z, 1];
p_4 = [point_2.x, point_2.y, point_1.z, 1];

plane = null( [p_1; p_2; p_3; p_4 ] );

% % plot the plane
% f = @(x,y,z) plane(1).*x + plane(2).*y + plane(3).*z + plane(4);
% fimplicit3(f,range3d)

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

% visualize surfaces
%figure;
patch( isosurface(x, y, z, f1, 0), 'FaceColor', [0.5 1.0 0.5], 'EdgeColor', 'none');
patch( isosurface(x, y, z, f2, 0), 'FaceColor', [1.0 0.5 0.0], 'EdgeColor', 'none');
view(3); camlight; axis vis3d;

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

line(xL,yL,zL,'Color','k','LineWidth',3);

%now draw just the pitch
pitch.draw();
% the camera
a = ver( 'MATLAB' );
if ~strcmp( a.Release, '(R2019b)')
    pose = rigid3d( data.R', data.O');
    [~] = plotCamera('AbsolutePose',pose,'Opacity',0, 'Size', 0.3);
end
% the 3d trajectory of the ball
line(xL,yL,zL,'Color','k','LineWidth',3);
end