function pointout = ball_foundlers_save_manual_clicked( setpoint )
    persistent point;
    persistent p_;
    
    if isempty( setpoint )
        pointout = point;
        point = zeros(2,2);
        p_ = 0;
        return;
    end
    
    if isempty( point ) | isempty( p_ )  
        point = zeros(2,2);
        p_ = 0;
    end

    if p_ == 0 | p_ == 2
        p_ = 1;
    else 
        p_ = 2;
    end
    
    point( p_ , : ) = setpoint;
    
    pointout = point;
end