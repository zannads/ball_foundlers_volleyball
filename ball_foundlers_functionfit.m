function [f, lin_param, matrix_param, inlier_idx] = ball_foundlers_functionfit( x, y, type, mode, varargin)
%BALL_FOUNDLERS_FUNCTIONFIT Fits the polynomial or the conic with the
%specified inputs. Mode specifies the algorithm, least squares or ransac.

if nargin == 6 && strcmp( varargin{1}, 'MaxDistance' )
    max_distance = varargin{2};
else
    max_distance = 10; % max allowable distance for inliers
end

if strcmp( type, 'line' )
    if strcmp( mode, 'lsq' )
        A = [x, y ];
        B = -ones( size(x, 1), 1);
        lin_param = pinv(A)*B;
        
        inlier_idx = [];
        
        a = lin_param(1);
        b = lin_param(2);
        c = 1;
        
    else % ransac
        sample_size = 2; % number of points to sample per trial because it is a line
        
        fitter = @(points) polyfit(points(:,1),points(:,2),1); % fit function using polyfit
        evaluator = ...   % distance evaluation function
            @(model, points) sum((points(:, 2) - polyval(model, points(:,1))).^2,2);
        
        [lin_param, inlier_idx] = ransac([x,y], fitter, evaluator, ...
            sample_size, max_distance);
        
        a = lin_param(1)/lin_param(2);
        b = -1/lin_param(2);
        c = 1;
        
        lin_param = [a; b];
    end
    
    matrix_param = lin_param;
    
    f = @(x, y) a.*x + b.*y + c;
    
    
elseif strcmp( type, 'conic' )
    if strcmp( mode, 'lsq' )
        lin_param = conicfit( [x, y] );
        inlier_idx = [];
        
    else %ransac
        sample_size = 5; % number of points to sample per trial because it is a conic
        
        fitter = @conicfit; % fit function using conics
        evaluator = @evalconic;   % distance evaluation function
        
        [lin_param, inlier_idx] = ransac( [x,y] , fitter, evaluator, ...
            sample_size, max_distance);
        
    end
    
    a = lin_param(1);
    b = lin_param(2);
    c = lin_param(3);
    d = lin_param(4);
    e = lin_param(5);
    
    matrix_param = [ a,    b/2, d/2;
        b/2,  c,   e/2;
        d/2,  e/2, 1];
    
    f = @(x ,y ) a.*x.^2 + b.*x.*y + c.*y.^2 + d.*x +e.*y + 1 ;
end

