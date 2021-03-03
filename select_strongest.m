function set_ = select_strongest( target, quantity, varargin  )
% allocate set_
set_.length = 0;
set_.centers = {};
set_.radii = {};
set_.d_prev = {};
set_.connect = {};  % idx of s_set where it is connected to

% first one has to be f_set
f_set = varargin{1};
if f_set.length
    distances = zeros( f_set.length, 1);
    for idx = 1: f_set.length
        distances( idx ) = norm( target.position - f_set.centers{ idx, : } ) ;
    end
    
    set_.length = min( quantity, f_set.length ) ;
    set_.centers{ set_.length, 1} = 0;
    set_.radii { set_.length, 1} = 0;
    set_.d_prev{ set_.length, 1} = 0;
    set_.connect{ set_.length, 1} = 0;
    idx = 1;
    max_ = max( distances) +1;
    while idx <= set_.length
        [m, n] = min( distances );
        
        %copy
        set_.centers{ idx } = f_set.centers{ n, : };
        set_.radii{ idx } = f_set.radii{ n };
        set_.d_prev{ idx } = m;
        set_.connect{ idx } = 0;
        
        % remove the used one
        distances( n ) = max_ ;
        idx = idx+1;
    end
end

% second one is s_set
% I compute the distance of every of these circles to the
% ones of f_set if close eneough I remove them
s_set = varargin{2};
if s_set.length
    distances = zeros( set_.length, s_set.length);
    for jdx = 1:s_set.length
        for idx = 1: set_.length
            distances( idx, jdx ) = norm( s_set.centers{ jdx } - set_.centers{ idx, : } ) ;
        end
    end
    
    kdx = min( set_.length, s_set.length ) ;
    numbers = 1:s_set.length;
    while kdx > 0 % and dim less then n
        [m, n] = min( distances , [], 'all', 'linear');
        if m <= 2*target.radii
            r = ceil( n/s_set.length ) ;
            c = n- (r-1)*s_set.length ;
            
            set_.connect{ r} = numbers(c);
            numbers(c) = [];
            
            distances(r, :) = [];
            distances(:, c) = [];
            
            s_set.length = s_set.length -1;
            s_set.centers(c, :) = [];
            s_set.radii(c, :) = [];
        end
        
        kdx = kdx-1;
    end
    
    % If I still have some circles not been asigned I add the
    % m to f_set
    if s_set.length
        distances = zeros( s_set.length, 1);
        for idx = 1: s_set.length
            distances( idx ) = norm( target.position - s_set.centers{ idx, : } ) ;
        end
        
        idx = set_.length+1;
        set_.length = set_.length + min( quantity, s_set.length ) ;
        set_.centers{ set_.length, 1} = 0;
        set_.radii { set_.length, 1} = 0;
        set_.d_prev{ set_.length, 1} = 0;
        set_.strength{ set_.length, 1} = 0;
        
        max_ = max( distances) +1;
        while idx <= set_.length
            [m, n] = min( distances );
            
            %copy
            set_.centers{ idx } = s_set.centers{ n, : };
            set_.radii{ idx } = s_set.radii{ n };
            set_.d_prev{ idx } = m;
            set_.strength{ idx } = 1;
            
            % remove the used one
            distances( n ) = max_ ;
            idx = idx+1;
        end
    end
    
end

end