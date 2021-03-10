function ball_foundlers_convert2dto3d( name, p_mat, point_1, point_2 )
if ~ exist( name, 'file' )
    return;
end

action = load( name );
%num_points = action.frame{end};


points = cell2mat( action.position );

idx_s  = find( points == point_1 );
%check for double points 
idx_e = find( points == point_2 );
x_ = points( idx_s(1):idx_e(1) )'; 
y_ = points( idx_s(2):idx_e(2) )';

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
range = [min( point_1(1), point_2(1) ), max( point_1(1), point_2(1) ), min( point_1(2), point_2(2) ), max( point_1(2), point_2(2) )]
fimplicit( eq, range );

% plottare i punti e chiedere constraints
% ask for i due constraints tra due punti
%   seleziona punto da grafico
%   % come chiedere per un punto su un grafico? / use brahsed and save
%   fai inserire x = -... 0 y = ... una delle 3 insomma
%       l'altro punto

% costruire la conica 
% plot la conica per controllare tra min x e max x 

% salvo point_1 _frame, _coordinata constraint
% salvo point_2, _frame, _coordinata constraint
% salvo conica 
% salvo quadrica 






end