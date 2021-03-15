function point_select_callback( src, ~ )
%POINT_SELECT_CALLBACK Callback funtion to attach to points for saving them
%when clicked on.

%get the point from where this function is called.
point = [src.XData, src.YData];

% save the point
ball_foundlers_save_manual_clicked( 'add', point );

% just let the user know
disp( 'Point acquired');
end