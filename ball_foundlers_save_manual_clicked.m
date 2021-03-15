function pointout = ball_foundlers_save_manual_clicked( command, varargin )
%BALL_FOUNDLERS_SAVE_MANUAL_CLICKED Function with persistent variable so
%that I can save global variables and call the between different functions.

%% setup
    persistent point;       % space for points to save
    persistent mem;         % number of points to save
    persistent p_;          % idx of last saved
    
    %create variables if it is the first call
    if isempty( point ) | isempty( p_ )  | isempty ( mem )
        mem = 0;
        point = zeros( mem  , 2);
        p_ = 0;
    end

    %% execution of the command
    if strcmp( command, 'reset' )
        % I can forget last save, reset all varaibles
        mem = 0;
        point = zeros( mem  , 2);
        p_ = 0;
        pointout = [];
        
    elseif strcmp( command, 'set' )
        % I need to save a new number of points. Preallocate the space
        mem = varargin{1};
        point = zeros( mem  , 2);
        p_ = 0;
        pointout = [];
        
    elseif strcmp( command, 'add' )
        % I have a new data to save
        if p_< mem
            % if there is still space move the index
            p_ = p_ +1;
            
            %save the point
            point( p_, :) = varargin{1};
        end
        
        %give back the pointsif they are saved
        pointout = point;
        
    elseif strcmp( command, 'is_acquired' )
        % similar to a get point, it returns something only if the process is done
       if p_ == mem
           pointout = point;
       else
           pointout = [];
       end
    end
end