function point_select_callback( src, ~ )
point = [src.XData, src.YData];

ball_foundlers_save_manual_clicked( 'add', point );

disp( 'Point acquired');
end