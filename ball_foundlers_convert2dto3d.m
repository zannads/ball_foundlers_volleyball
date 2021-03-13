function ball_foundlers_convert2dto3d( data, start_frame )
if isempty( data.detected )
    return;
end
ball_foundlers_show( data, '2d', 'background', start_frame );

[point_1, point_2] = ball_foundlers_extract_points( data, 'plane' );

[x_, y_] = ball_foundlers_extract_points( data, 'conic' );

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
  % improve with ransac? 


  
hold on; 
eq = @(x ,y ) a.*x.^2 + b.*x.*y + c.*y.^2 + d.*x +e.*y + 1 ;
range2d = [min( x_(1), x_(end) ), max( x_(1), x_(end) ),...
    1, 720];
fimplicit( eq, range2d );

% costruire la conica 
% plot la conica per controllare tra min x e max x 

P = data.P;

  Q = P'*C*P;
  Q_lin = [Q(1, 1), 2*Q(1, 2), 2*Q(1, 3), 2*Q(1, 4),...
                      Q(2, 2), 2*Q(2, 3), 2*Q(2, 4),...
                                 Q(3, 3), 2*Q(3, 4),...
                                            Q(4, 4)];
  
  pitch = volleyball_pitch();
  pitch.draw();
  
f = @(x,y,z) Q_lin(1).*x.^2 + Q_lin(2).*x.*y + Q_lin(3).*x.*z + Q_lin(4).*x ...
                            + Q_lin(5).*y.^2 + Q_lin(6).*y.*z + Q_lin(7).*y ...
                                             + Q_lin(8).*z.^2 + Q_lin(9).*z ...
                                                              + Q_lin(10);
                
range3d = data.range;
fimplicit3(f,range3d)


% extract vertical plane from the two points. 
p_1 = [point_1.x, point_1.y, point_1.z, 1];
p_2 = [point_2.x, point_2.y, point_2.z, 1];
p_3 = [point_1.x, point_1.y, point_2.z, 1];
p_4 = [point_2.x, point_2.y, point_1.z, 1];

plane = null( [p_1; p_2; p_3; p_4 ] );

  f = @(x,y,z) plane(1).*x + plane(2).*y + plane(3).*z + plane(4);
fimplicit3(f,range3d)

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

figure; 
patch( isosurface(x, y, z, f1, 0), 'FaceColor', [0.5 1.0 0.5], 'EdgeColor', 'none');
patch( isosurface(x, y, z, f2, 0), 'FaceColor', [1.0 0.5 0.0], 'EdgeColor', 'none');
view(3); camlight; axis vis3d;

% Find the difference field.
f3 = f1 - f2;
% Interpolate the difference field on the explicitly defined surface.
f3s = interp3(x, y, z, f3, x2, y2, z2);
% Find the contour where the difference (on the surface) is zero.
C_ = contours(x2, y2, f3s, [0 0]);
% Extract the x- and y-locations from the contour matrix C.
xL = C_(1, 2:end);
yL = C_(2, 2:end);
C_ = contours(x2, z2, f3s, [0 0]);
zL =  C_(2, 2:end);
% Interpolate on the first surface to find z-locations for the intersection
% line.
%zL = interp2(x2, y2, z2, xL, yL);
% Visualize the line.
line(xL,yL,zL,'Color','k','LineWidth',3);

 pitch.draw();
 
 pose = rigid3d( data.R', data.O');
cam = plotCamera('AbsolutePose',pose,'Opacity',0, 'Size', 0.3);

line(xL,yL,zL,'Color','k','LineWidth',3);

end