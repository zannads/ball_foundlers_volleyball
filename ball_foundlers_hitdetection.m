function point3d = ball_foundlers_hitdetection( ball, info )
%BALL_FOUNDLERS_HITDETECTION 

global debug_hitdetection;
if debug_hitdetection 
    p = ball.last_known;
    
    mem = length( info );
    r = 2;
    c = mem/r;
    
    figure; 
    for idx = 1:mem
    subplot(r, c, idx); 
    imshow( info(idx).frames); hold on; 
     plot( p(1), p(2), 'or');
     p_ = detectHarrisFeatures( rgb2gray( info(idx).frames ) );
     plot( p_ );
    end
    
    figure; 
    for idx = 1:mem
    subplot(r, c, idx); 
    imshow( info(idx).reports.foreground.mask); hold on; 
     plot( p(1), p(2), 'or');
    end
    
     figure; 
    for idx = 1:mem
    subplot(r, c, idx); 
    imshow( info(idx).reports.stepper.mask); hold on; 
     plot( p(1), p(2), 'or');
    end
    
   close all;
end
end