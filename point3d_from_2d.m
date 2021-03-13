function point = point3d_from_2d( u, v, P, fix_coord_name, fix_coord_value )
syms x y z k

eq = [u == k*(P(1,1)*x + P(1,2)*y +P(1,3)*z + P(1,4) ), ...
      v == k*(P(2,1)*x + P(2,2)*y +P(2,3)*z + P(2,4) ), ...
      1 == k*(P(3,1)*x + P(3,2)*y +P(3,3)*z + P(3,4) )];
  
 eq = subs( eq, fix_coord_name, fix_coord_value );
  
  
  
  if strcmp( fix_coord_name, 'x' )
      [v_1, v_2, ~] = solve( eq, [y, z, k] );
      point.x = fix_coord_value;
      point.y = double( v_1 );
      point.z = double( v_2 );
      
  elseif strcmp( fix_coord_name, 'y' )
      [v_1, v_2, ~] = solve( eq, [x, z, k] );
      point.y = fix_coord_value;
      point.x = double( v_1 );
      point.z = double( v_2 );
      
  else
      [v_1, v_2, ~] = solve( eq, [x, y, k] );
      point.z = fix_coord_value;
      point.x = double( v_1 );
      point.y = double( v_2 );
      
  end

end