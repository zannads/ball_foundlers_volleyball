function pointout = ball_foundlers_save_manual_clicked( command, varargin )
    persistent point;
    persistent mem;
    persistent p_;
    
    
    
    if isempty( point ) | isempty( p_ )  | isempty ( mem )
        mem = 0;
        point = zeros( mem  , 2);
        p_ = 0;
    end

    if strcmp( command, 'reset' )
        mem = 0;
        point = zeros( mem  , 2);
        p_ = 0;
        pointout = [];
        
    elseif strcmp( command, 'set' )
        mem = varargin{1};
        point = zeros( mem  , 2);
        p_ = 0;
        pointout = [];
        
    elseif strcmp( command, 'add' )
        if p_< mem
            p_ = p_ +1;
            
            point( p_, :) = varargin{1};
        end
        pointout = point;
        
    elseif strcmp( command, 'is_acquired' )
       if p_ == mem
           pointout = point;
       else
           pointout = [];
       end
    end
end