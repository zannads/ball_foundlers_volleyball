prog_dir = '/Users/denniszanutto/Documents/GitHub/ball_foundlers_volleyball';
file_dir = '/Users/denniszanutto/Downloads/Pallavolo.mp4';

save_pos_folder = '/Users/denniszanutto/Downloads/pos_samples';
addpath(save_pos_folder);
save_neg_folder = '/Users/denniszanutto/Downloads/neg_samples';

video_reader = VideoReader( file_dir);
T = video_reader.Duration;


a = dir([save_pos_folder '/*.jpg']);
pos_saved = numel(a);
pos_root = "pos_im_";
a = dir([save_neg_folder '/*.jpg']);
neg_saved = numel(a);
neg_root = "neg_im_";
clear a;

try
    saved_frames = load( 'saved_frames.mat' );
    saved_frames = saved_frames.saved_frames;
catch error
    saved_frames = 0;
end

idx = 1;
while idx ~= 0
    
    %extract a random time
    desired_time = rand(1)*T;
    
    if ( sum( saved_frames == desired_time ) > 0)
        % don't do anithing
    else
        % extract its frame
        video_reader.CurrentTime = desired_time;
        frame   = readFrame(video_reader);
        saved_frames = [saved_frames; desired_time];
        
        % show up to date information
        disp('Saved images positive:');
        disp( num2str( max( pos_saved-1, 0) ) );
        disp('Saved images negative:');
        disp( num2str( max( neg_saved-1, 0) ) );
        
        imshow( frame );
        title( strcat( "Pos: ", num2str(max( pos_saved-1, 0) ), " | Neg: ", num2str( max( neg_saved-1, 0) ) ) );
        
        % ask for localization
        answer = questdlg('Next action?', 'Action required', ...
            'Positive', 'Negative', 'Quit', 'Quit');
        % if yes
        %       image in positive sample
        % if not
        %       image sample negative
        % if quit
        %       show all and bye bye
        
        if (strcmp( answer, 'Positive' ) )
            cd( save_pos_folder );
            print( strcat( pos_root, num2str(pos_saved) ) , '-djpeg' );
            cd( prog_dir );
            pos_saved = pos_saved +1;
        elseif ( strcmp( answer, 'Negative' ) )
            cd( save_neg_folder );
            print( strcat( neg_root, num2str(neg_saved) ) , '-djpeg' );
            cd( prog_dir );
            neg_saved = neg_saved +1;
        else
            close all;
            disp('DATASET:');
            disp('Saved images positive:');
            disp(pos_saved-1);
            disp('Saved images negative:');
            disp(neg_saved-1);
            idx = 0;
            
            % save again the frame we used to avoid duplications 
            % last one added hasn't been saved
            saved_frames = saved_frames(1:end-1);
            save('saved_frames.mat', 'saved_frames');
        end
    end
    
end
%%
% now it's time to label
videoLabeler( save_pos_folder );

% %save( gTruth );
%%
positive_data = table( gTruth.DataSource.Source, gTruth.LabelData.ball );

%%
% now it's possible to start training
% positive data already uploaded


negative_data = imageDatastore(save_neg_folder);

trainCascadeObjectDetector('ball_foundler.xml',positive_data, ...
    negative_data,'FalseAlarmRate',0.1,'NumCascadeStages',5);

detector = vision.CascadeObjectDetector('ball_foundler.xml');

%%
% I should do validation
%extract a random time
desired_time = rand(1)*T;

% extract its frame
video_reader.CurrentTime = desired_time;
frame   = readFrame(video_reader);
bbox = step(detector,frame);

detectedImg = insertObjectAnnotation(frame,'rectangle',bbox,'Ball');

figure; imshow(detectedImg);

figure; imshow(frame);
[featureVector,hogVisualization]  = extractHOGFeatures(frame);
hold on 
plot(hogVisualization);

%%
I = rgb2gray(frame);
bw = imbinarize(I);
imshow(bw)
g = frame(:,:,2);
[m, v] = size(g);
figure;
imshow( frame &( g > 100) & (g<200) &  );
title('G');
figure;
imshow(frame(:,:,3))