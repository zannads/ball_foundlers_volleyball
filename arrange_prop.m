function set_ = arrange_prop( mask )
        set_.mask = mask;
        
        [centers, radii] = imfindcircles(mask, [3, 15]); 
        
        set_.length = size( centers, 1);
        set_.centers = cell( set_.length, 1 );
        set_.radii = cell( set_.length, 1 );
        for idx = 1:size( centers, 1)
            set_.centers{idx} = centers( idx, : );
            set_.radii{idx} = radii( idx, : );
        end
end