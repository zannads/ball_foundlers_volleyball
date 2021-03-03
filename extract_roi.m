function [roi_mask, v_x, v_y] = extract_roi( mask, x_y, semi_width)
           
            bound = bbox_from_circle( x_y, semi_width, 'vectorial', 'Limits', size( mask ) );
            
            roi_mask = mask( bound(1):bound(2), bound(3):bound(4) );
            v_x = bound(3);
            v_y = bound(1);
        end