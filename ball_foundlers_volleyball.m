prog_dir = '/Users/denniszanutto/Documents/GitHub/ball_foundlers_volleyball';
file_dir = '/Users/denniszanutto/Downloads/Pallavolo_1.mp4';


videoReader = VideoReader( file_dir);
videoReader.CurrentTime = 5;
videoFrame      = readFrame(videoReader);

 im_g = rgb2gray(videoFrame);
edgs = edge(im_g,'canny', [0.08, 0.2]);
figure;
imshow(edgs)
%%
num_lines = 3;

%super ok dire 1 e 2
canny_pam = {[0.1, 0.5], [0.1, 0.5], [0.08, 0.15]};
rho_res = {1, 1, 1};
theta_res = {30:0.1:85, -84.5:0.1:-40, -10:0.1:10};
n_hood_size = { [61, 51], [61, 101], [59, 5]};  %default sizeH/50
fill_gap_length = 10; %default 20
min_length = {100, 30, 20};

limit_n_lines = 10;

% start of selected lines, the algorithm does this:
% for every direction from 1 to 6,
%   uploads the masks
%   runs canny
%   Hough lines detection (output is an array of segments)
%   regroup the segments in the same direction (almost a line)
%   displays this set
%   asks for confirmation
%   if line is confirmed,
%           transforms from Hough params to my line class
%           change of coordinates

set_plines = cell( num_lines, 1 );
idx = 1;
while idx <= num_lines
    
    edgs = edge(im_g, 'canny', canny_pam{idx});
    %figure; imshow(edgs);
    
    [H,theta,rho] = hough(edgs, 'RhoResolution', rho_res{idx}, 'Theta', theta_res{idx});
    P = houghpeaks(H, limit_n_lines, 'threshold', ceil(0.3*max(H(:))), 'NHoodSize', n_hood_size{idx});
    lines = houghlines(edgs,theta,rho,P,'FillGap',fill_gap_length,'MinLength',min_length{idx});
    
    glines = regroup_houghlines( lines );
    
    f_h = figure; imshow(videoFrame); hold on;
    
    k = 1;
    while k <= length( glines )
        % title( strcat( "Select lines parallel to ", title_select(idx) ) );
        
        line_ = glines{k};
        
        figure(f_h);hold on;
        for m = 1:length( line_ )
            xy = [line_(m).point1; line_(m).point2];
            plot(xy(:,1), xy(:,2),'LineWidth',2,'Color','green');
            
            % Plot beginnings and ends of lines
            plot(xy(1,1), xy(1,2), 'x','LineWidth',2,'Color','yellow');
            plot(xy(2,1), xy(2,2), 'x','LineWidth',2,'Color','red');
            
            text( (xy(2,1)+xy(1,1))/2, (xy(2,2)+xy(1,2))/2, num2str(k) );
        end
        
        %transform it into myclass
        lines_to_transform = glines{k}(1);
        a = cos( lines_to_transform.theta * pi/180 );
        b = sin( lines_to_transform.theta *pi/180);
        c =  -lines_to_transform.rho ;
        general_line = abs_line ( [a; b; c]/ c );
        %add to te ones already saved
        set_plines{idx} = [set_plines{idx}; general_line];
        
        k = k+1;
    end
    idx = idx+1;
end
hold off;

% when i need to save them for geometry
%    save('parallel_lines.mat', 'set_plines');

%%
% define points 
set_vpoints(3,1) = abs_point();
set_vpoints(1) = estimate_lsq( set_plines{1}, 'vp', 'v1' );
set_vpoints(2) = estimate_lsq( set_plines{2}, 'vp', 'v2' );
set_vpoints(3) = estimate_lsq( set_plines{3}([1, 2, 4, 5, 6, 7, 8]), 'vp', 'v3');

% it Would be nice to do it from the image
% str = input(prompt,'s')
lx_1 = set_plines{2}(1);
lx_0 = set_plines{2}(2);

ly_0 = set_plines{1}(2);
ly_1 = set_plines{1}(1);
ly_2 = set_plines{1}(6);
ly_1n = set_plines{1}(5);
%ly_2n = set_plines{1}(5);

net_up = set_plines{1}(4);
%net_height = 2.24; %m %femminile
net_height = 2.43; %m

pitch_coordinates = [0, 0, 0;
          3, 0, 0;
          9, 0, 0;
          9, 9, 0;
          3, 9, 0;
          0, 9, 0;
          -9, 9, 0;
          -9, 0, 0;
          0, 0, net_height;
          0, 9, net_height];
          
%A 
pitch_im(1) = abs_point( lx_0.intersection( ly_0 ), 'A');
%B 
pitch_im(2) = abs_point( lx_0.intersection( ly_1 ), 'B');
%C 
pitch_im(3) = abs_point( lx_0.intersection( ly_2 ), 'C');
%D
pitch_im(4) = abs_point( lx_1.intersection( ly_2 ), 'D');
%E
pitch_im(5) = abs_point( lx_1.intersection( ly_1 ), 'E');
%F
pitch_im(6) = abs_point( lx_1.intersection( ly_0 ), 'F');
%G
pitch_im(7) = abs_point( lx_1.intersection( ly_0 ), 'G');
%H
%pitch_im(7) = abs_point( lx_1.intersection( ly_2n ), 'H');
%I 
pitch_im(8) = abs_point( lx_0.intersection( ly_2n ), 'I');

lz_0 = abs_line( pitch_im(1).passing_line( set_vpoints(3) ) );
lz_1 = abs_line( pitch_im(6).passing_line( set_vpoints(3) ) );

%A_
pitch_up_im(1) = abs_point( net_up.intersection( lz_0 ), 'A_');
%F_
pitch_up_im(2) = abs_point( net_up.intersection( lz_1 ), 'F_');

f_h = figure;
imshow(videoFrame);
for idx = 1:length( pitch_im )
pitch_im(idx).draw( 'at', f_h);
end
pitch_up_im(1).draw( 'at', f_h);
pitch_up_im(2).draw( 'at', f_h);

%%
imagePoints = zeros( size(pitch_coordinates,1 ), 2 );
for idx = 1 : (length(pitch_im ) )
   imagePoints(idx, :) = pitch_im(idx).params(1:2)'; 
end
for idx = 1 : + length(pitch_up_im) 
    imagePoints(idx + length(pitch_im ) , :) = pitch_up_im(idx).params(1:2)'; 
end

P = estimateCameraMatrix( imagePoints, pitch_coordinates );
P = P';
P*[ pitch_coordinates'; ones(1, 10)]

M = P(:, 1:3);
m = P(:, end);

[R, K] = qr( M' )
O = -M\m;

figure;
plot3( pitch_coordinates(:, 1), pitch_coordinates(:, 2), pitch_coordinates(:, 3), 'or'); 
grid on;
hold on;
pose = rigid3d( R', O');
cam = plotCamera('AbsolutePose',pose,'Opacity',0, 'Size', 0.3);
% to draw a coloured rectangle
% rectangle

%%
%try to find the homography between images

