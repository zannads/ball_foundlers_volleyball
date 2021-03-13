function a_h = ball_foundlers_calibration( a_h )

videoReader = VideoReader( a_h.get_videoname );
%videoReader.CurrentTime = 130;
video_frame      = readFrame(videoReader);

% peopleDetector = vision.PeopleDetector;
% [bboxes,scores] = peopleDetector(video_frame);
% video_frame = insertObjectAnnotation(video_frame,'rectangle',bboxes,scores);
figure, imshow(video_frame)
% title('Detected people and detection scores');


im_g = rgb2gray(video_frame);
% edgs = edge(im_g,'canny', [0.08, 0.2]);
% figure;
% imshow(edgs)
%
directions = 3;

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

% cell for lines on every of the 3 directions
set_plines = cell( directions, 1 );
%vanishing points for the 3 directions
set_vpoints(3,1) = abs_point();

idx = 1;
while idx <= directions
    
    edgs = edge(im_g, 'canny', canny_pam{idx});
    %figure; imshow(edgs);
    
    [H,theta,rho] = hough(edgs, 'RhoResolution', rho_res{idx}, 'Theta', theta_res{idx});
    P = houghpeaks(H, limit_n_lines, 'threshold', ceil(0.3*max(H(:))), 'NHoodSize', n_hood_size{idx});
    lines = houghlines(edgs,theta,rho,P,'FillGap',fill_gap_length,'MinLength',min_length{idx});
    
    glines = regroup_houghlines( lines );
    
    f_h = figure; imshow(video_frame); hold on;
    
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
    set_vpoints(idx) = estimate_lsq( set_plines{idx}, 'vp', strcat('v', num2str(idx) ) );
    
    if (idx == 2)
        
        prompt = 'Insert the number of the line of the pitch along ly_0. If not present insert 0';
        str = input(prompt);
        if (str == 0 )
            ly_0 = abs_line();
        else
            ly_0 = set_plines{idx}(str);
        end
        
        prompt = 'Insert the number of the line of the pitch along ly_1. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            ly_1 = abs_line();
        else
            ly_1 = set_plines{idx}(str);
        end
        
        prompt = 'Insert the number of the line of the pitch along ly_2. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            ly_2 = abs_line();
        else
            ly_2 = set_plines{idx}(str);
        end
        
        prompt = 'Insert the number of the line of the pitch along ly_1n. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            ly_1n = abs_line();
        else
            ly_1n = set_plines{idx}(str);
        end
        
        prompt = 'Insert the number of the line of the pitch along ly_2n. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            ly_2n = abs_line();
        else
            ly_2n = set_plines{idx}(str);
        end
        
        prompt = 'Insert the number of the line of the upper part of the net. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            net_up = abs_line();
        else
            net_up = set_plines{idx}(str);
        end
        prompt = 'Insert the number of the line of the lower part of the net. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            net_down = abs_line();
        else
            net_down = set_plines{idx}(str);
        end
        
    elseif (idx == 1)
        
        prompt = 'Insert the number of the line of the pitch along lx_0. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            lx_0 = abs_line();
        else
            lx_0 = set_plines{idx}(str);
        end
        
        prompt = 'Insert the number of the line of the pitch along lx_1. If not present insert 0';
        str = input(prompt);
        if (str == 0)
            lx_1 = abs_line();
        else
            lx_1 = set_plines{idx}(str);
        end
        
    else
        
    end
    
    idx = idx+1;
    
end

real_pitch = volleyball_pitch();
image_pitch = volleyball_pitch( video_frame );

image_pitch = image_pitch.add_point( lx_0, ly_0, 'A');
image_pitch = image_pitch.add_point( lx_0, ly_1, 'B');
image_pitch = image_pitch.add_point( lx_0, ly_2, 'C');
image_pitch = image_pitch.add_point( lx_1, ly_2, 'D');
image_pitch = image_pitch.add_point( lx_1, ly_1, 'E');
image_pitch = image_pitch.add_point( lx_1, ly_0, 'F');
image_pitch = image_pitch.add_point( lx_1, ly_1n, 'G');
image_pitch = image_pitch.add_point( lx_1, ly_2n, 'H');
image_pitch = image_pitch.add_point( lx_0, ly_2n, 'I');
image_pitch = image_pitch.add_point( lx_0, ly_1n, 'J');

lz_0 = abs_line( image_pitch.pitch(1).passing_line( set_vpoints(3) ) );
lz_1 = abs_line( image_pitch.pitch(6).passing_line( set_vpoints(3) ) );

image_pitch = image_pitch.add_point( lz_0, net_up, 'A_');
image_pitch = image_pitch.add_point( lz_1, net_up, 'F_');
image_pitch = image_pitch.add_point( lz_0, net_down, 'A__');
image_pitch = image_pitch.add_point( lz_1, net_down, 'F__');

[P, R, K, O] = extract_camera_from_pitches( image_pitch ,real_pitch);

image_pitch.draw();

real_pitch.draw();
hold on;
pose = rigid3d( R', O');
cam = plotCamera('AbsolutePose',pose,'Opacity',0, 'Size', 0.3);

[image_pitch_, error] = image_pitch.complete(P, real_pitch);

%save stuff 
a_h = a_h.set_P( P );
a_h = a_h.set_camera_position( O );
a_h = a_h.set_camera_rotation( R );
a_h = a_h.set_camera_parameters( K );
a_h.save_all;
end