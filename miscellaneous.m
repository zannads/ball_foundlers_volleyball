a_h = actions_handler( cd, 'actions.mat');

close all;
videoReader = VideoReader( a_h.get_videoname );
videoReader.CurrentTime = a_h.set.action_1.ball_s_time;
video_frame      = readFrame(videoReader);


hsv_frame = rgb2hsv( video_frame );
figure; imshow(hsv_frame);
figure; imshow(video_frame);
 a = detectHarrisFeatures(rgb2gray(video_frame));
 hold on; plot(a);
 figure; imshow( edge( rgb2gray(video_frame ), 'canny' ) )



[x, y] = getpts();
x = ceil(x);
y = ceil(y);
a = hsv_frame( y(1):y(2), x(1):x(2), :);
b = video_frame( y(1):y(2), x(1):x(2), :);
figure; imshow(a);
figure; imshow(b);
color = [0.15, 0.25];
s = [0.1 , 0.3];
v = [0.2, 0.4];


I1 = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
I2 = ( hsv_frame(:,:,2) > min(s) & hsv_frame(:,:,2) < max(s));
I3 = ( hsv_frame(:,:,3) > min(v) & hsv_frame(:,:,3) < max(v));
mask = I1 & I2 & I3;
%mask = imopen(mask, strel('rectangle', [3,3]));
       mask = imclose(mask, strel('rectangle', [15, 15])); 
        mask = imfill(mask, 'holes');

figure;
imshow( mask );

[centers, radii] = imfindcircles(mask, [3, 15])
h = viscircles(centers,radii);



        

 b = detectHarrisFeatures(rgb2gray(video_frame_2));
 figure; imshow(video_frame_2);
  hold on; plot(b);

 
  %%
  % idea 
% vado al secondo che mi interessa il primo del salto. 
% acquisisco i 25 frame succ 
load jump3.mat jump
% rimuovo leharris features costanti in tutti
jump.points = remove_static_harrisfeatures( jump.points );
% ora prendo le rimanenti nella bbox che mi interessa 
jump.points = select_roi_harrisfeatures( jump.points, jump.bbox );
% mostro cosa c'è
figure; imshow( jump.frame{1} );
hold on;
colors = 'rgbmcykw';
for idx = 1:length( jump.frame )
    clr = colors( mod( idx, length(colors) ) +1 );
    points = jump.points{idx}.Location;
    plot( points(:, 1), points(:, 2), strcat('*', clr) );
    rectangle( 'Position', jump.bbox{idx}, 'EdgeColor', clr );
end

jump.points = select_foot_harrisfeatures( jump.points );

figure; imshow( jump.frame{1} );
hold on;
colors = 'rgbmcykw';
for idx = 1:length( jump.frame )-1
    clr = colors( mod( idx, length(colors) ) +1 );
    points = [jump.points{idx}.Location; jump.points{idx+1}.Location];
    plot( points(:, 1), points(:, 2), clr );
end

%%
x_ = zeros( size(jump.frame, 2), 1);
y_ = zeros( size(jump.frame, 2), 1);

for idx = 1:length( jump.frame )
    x_(idx) = jump.points{idx}.Location(1);
    y_(idx) = jump.points{idx}.Location(2);
end

%% times 