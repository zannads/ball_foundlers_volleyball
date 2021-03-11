function ball_foundlers_convert2dto3d( name, point_1, point_2 )
if ~ exist( name, 'file' )
    return;
end

action = load( name );
%num_points = action.frame{end};


points = cell2mat( action.position(point_1.time : point_2.time) );


x_ = points( :, 1 ); 
y_ = points( :, 2 );

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
%syms x_ y_ ;
eq = @(x ,y ) a.*x.^2 + b.*x.*y + c.*y.^2 + d.*x +e.*y + 1 ;
%eq  = strcat( num2str(a), '*x_^2 + ', num2str(b),' *x_*y_ + ', num2str(c), '*y_^2 + ', num2str(d), '*x_ + ', num2str(e), '*y_ + 1 == 0');
range = [min( point_1.dd_c(1), point_2.dd_c(1) ), max( point_1.dd_c(1), point_2.dd_c(1) ),...
    1, 720];
fimplicit( eq, range );

% costruire la conica 
% plot la conica per controllare tra min x e max x 

  load( 'proj_mat.mat', 'P' );
  
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
                
interval = [-9 9 0 9 0 5];
fimplicit3(f,interval)


% extract vertical plane from the two points. 
p_1 = [point_1.x, point_1.y, point_1.z, 1];
p_2 = [point_2.x, point_2.y, point_2.z, 1];
p_3 = [point_1.x, point_1.y, point_2.z, 1];
p_4 = [point_2.x, point_2.y, point_1.z, 1];

plane = null( [p_1; p_2; p_3; p_4 ] );

  f = @(x,y,z) plane(1).*x + plane(2).*y + plane(3).*z + plane(4);
fimplicit3(f,interval)

%define input grid
[x, y, z] = meshgrid( linspace( interval(1), interval(2) ), ...
                                linspace( interval(3), interval(4) ), ...
                                linspace( interval(5), interval(6) ) );
% compute implicity defined function
f1 =  Q_lin(1).*x.^2 + Q_lin(2).*x.*y + Q_lin(3).*x.*z + Q_lin(4).*x ...
                            + Q_lin(5).*y.^2 + Q_lin(6).*y.*z + Q_lin(7).*y ...
                                             + Q_lin(8).*z.^2 + Q_lin(9).*z ...
                                                              + Q_lin(10);
f2 = plane(1).*x + plane(2).*y + plane(3).*z + plane(4);

% compute y of the plane starting from x and z
[x2, z2] = meshgrid( linspace( interval(1), interval(2) ), ...
    linspace( interval(5), interval(6) ) );
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


end