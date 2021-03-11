prog_dir = '/Users/denniszanutto/Documents/GitHub/ball_foundlers_volleyball';
file_dir = '/Users/denniszanutto/Downloads/Pallavolo_1.mp4';

close all;
videoReader = VideoReader( file_dir);
%videoReader.CurrentTime = 130;
video_frame      = readFrame(videoReader);


hsv_frame = rgb2hsv( video_frame );
figure; imshow(hsv_frame);
figure; imshow(video_frame);
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

%%
prog_dir = '/Users/denniszanutto/Documents/GitHub/ball_foundlers_volleyball';
file_dir = '/Users/denniszanutto/Downloads/Pallavolo_1.mp4';

close all;
videoReader = VideoReader( file_dir);
videoReader.CurrentTime = rand(1)*videoReader.Duration;
video_frame      = readFrame(videoReader);
video_frame_2      = readFrame(videoReader);


hsv_frame = rgb2hsv( video_frame );
hsv_frame_2 = rgb2hsv( video_frame_2 );
figure; imshow(hsv_frame);
figure; imshow(hsv_frame_2);
% [x, y] = getpts();
% x = ceil(x);
% y = ceil(y);
% a = hsv_frame( y(1):y(2), x(1):x(2), :);
% b = video_frame( y(1):y(2), x(1):x(2), :);
% figure; imshow(a);
% figure; imshow(b);
color = [0.15, 0.25];
s = [0.1 , 0.3];
v = [0.2, 0.4];


I1 = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
 I2 = ( hsv_frame_2(:,:,1) > min(color) & hsv_frame_2(:,:,1) < max(color));
% I3 = ( hsv_frame(:,:,3) > min(v) & hsv_frame(:,:,3) < max(v));
mask = I1; % & I2 & I3;
%mask = imopen(mask, strel('rectangle', [3,3]));
       mask = imclose(mask, strel('rectangle', [15, 15])); 
        mask = imfill(mask, 'holes');

figure;
imshow( mask );

[centers, radii] = imfindcircles(mask, [3, 15])
h = viscircles(centers,radii);

%%
bboxes = [x(1), y(1), x(2)-x(1), y(2)-y(1)];
color = [0.15, 0.25];
        if size(bboxes, 1) >= 1
        hsv_frame = frame( bboxes(1, 1):bboxes(1, 1)+bboxes(1, 3), bboxes(1, 1):bboxes(1, 1)+bboxes(1, 3), :);
        hsv_frame = rgb2hsv( hsv_frame );
        I1 = ( hsv_frame(:,:,1) > min(color) & hsv_frame(:,:,1) < max(color));
        r = sum( I1, [1, 2])/ (size(I1, 1)*size(I1,2));
        end
        
        
        %%
        prog_dir = '/Users/denniszanutto/Documents/GitHub/ball_foundlers_volleyball';
file_dir = '/Users/denniszanutto/Downloads/Pallavolo_1.mp4';

close all;
videoReader = VideoReader( file_dir);
videoReader.CurrentTime = rand(1)*videoReader.Duration;
video_frame      = readFrame(videoReader);
video_frame_2      = readFrame(videoReader);
figure; imshow(video_frame);

[x, y] = getpts();
x = ceil(x);
y = ceil(y);
b = video_frame( y(1):y(2), x(1):x(2), :);
figure; imshow(b);

figure; imshow(video_frame_2);

[x, y] = getpts();
x = ceil(x);
y = ceil(y);
a = video_frame_2( y(1):y(2), x(1):x(2), :);
figure; imshow(a);

r_1 = b(:,:,1);
g_1 = b(:,:,2);
b_1 = b(:,:,3);

r_2 = video_frame_2(:,:,1);
g_2 = video_frame_2(:,:,2);
b_2 = video_frame_2(:,:,3);

justGreen = g_2 - r_2/2 - b_2/2;

bw = justGreen > 5;
figure; imshow(bw);

k = abs(video_frame(:,:,1) - video_frame_2(:,:,1));
j = abs(video_frame(:,:,2) - video_frame_2(:,:,2));
l = abs(video_frame(:,:,3) - video_frame_2(:,:,3));

mask = k+j+l;
mask = mask./max(mask, [], 'all' )*255;
 imshow(mask);

m = conv2( video_frame_2(:,:,1), b(:,:,1));
m = m./ max( m, [], 'all');
m = conv2( video_frame_2(:,:,1), b(:,:,1));
m = m./ max( m, [], 'all');
m = conv2( video_frame_2(:,:,1), b(:,:,1));
m = m./ max( m, [], 'all');

imshow(m);

%%
close all
videoReader = VideoReader( file_dir);
%videoReader.CurrentTime = rand(1)*videoReader.Duration;
video_frame      = readFrame(videoReader);
video_frame_2      = readFrame(videoReader);
figure; imshow(video_frame);
 a = detectHarrisFeatures(rgb2gray(video_frame));
 hold on; plot(a);
 b = detectHarrisFeatures(rgb2gray(video_frame_2));
 figure; imshow(video_frame_2);
  hold on; plot(b);

  %%
  a = [1, 2, 3, 1]; b = [1, 2, 0, 1]; c = [3, 4, 3, 1]; d = [3, 4, 1, 1];
null( [a; b; c; d] )
  
   f = @(x,y,z) plane(1).*x + plane(2).*y + plane(3).*z + plane(4);
interval = [-100 100 -100 100 0 100];
fimplicit3(f,interval)

%%
% Define the input grid (in 3D)
[x3, y3, z3] = meshgrid(linspace(-1,1));
% Compute the implicitly defined function x^2 + y^2 + z^3 - 0.5^2 = 0
f1 = x3.^2 + y3.^2 + z3.^2 - 0.5^2;
% This surface is z = 2*y - 6*x^3, which can also be expressed as
% 2*y - 6*x^3 - z = 0.
f2 = 2*y3 - 6*x3.^3 - z3;
% Also compute z = 2*y - 6*x^3 in the 'traditional' way.
[x2, y2] = meshgrid(linspace(-1,1));
z2 = 2*y2 - 6*x2.^3;
% Visualize the two surfaces.
patch(isosurface(x3, y3, z3, f1, 0), 'FaceColor', [0.5 1.0 0.5], 'EdgeColor', 'none');
patch(isosurface(x3, y3, z3, f2, 0), 'FaceColor', [1.0 0.5 0.0], 'EdgeColor', 'none');
view(3); camlight; axis vis3d;
% Find the difference field.
f3 = f1 - f2;
% Interpolate the difference field on the explicitly defined surface.
f3s = interp3(x3, y3, z3, f3, x2, y2, z2);
% Find the contour where the difference (on the surface) is zero.
C = contours(x2, y2, f3s, [0 0]);
% Extract the x- and y-locations from the contour matrix C.
xL = C(1, 2:end);
yL = C(2, 2:end);
% Interpolate on the first surface to find z-locations for the intersection
% line.
zL = interp2(x2, y2, z2, xL, yL);
% Visualize the line.
line(xL,yL,zL,'Color','k','LineWidth',3);