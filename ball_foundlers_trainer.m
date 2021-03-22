save_pos_folder = '/Users/denniszanutto/Downloads/pos_samples';
save_neg_folder = fullfile(matlabroot,'toolbox','vision','visiondata',...
    'nonStopSigns');
addpath(save_pos_folder);
a_h = actions_handler( '/Users/denniszanutto/Documents/GITHub/ball_foundlers_volleyball/', 'actions.mat');
video_reader = VideoReader( a_h.get_videoname );
T = video_reader.Duration;

% videoLabeler('/Users/denniszanutto/Downloads/Pallavolo_1.mp4');

%%
cd('/Users/denniszanutto/Documents/MATLAB Drive/ball_foundlers');
load('4actions_track.mat', 'gTruth' );
%positive_data = table( {gTruth.DataSource.Source}, gTruth.LabelData.player );

%
% now it's possible to start training
% positive data already uploaded

cd( save_pos_folder );
negative_data = imageDatastore(save_neg_folder);

positive_data = objectDetectorTrainingData(gTruth);
%%
cd( '/Users/denniszanutto/Documents/Matlab Drive/ball_foundlers' );
trainCascadeObjectDetector('ball_foundler.xml',positive_data, ...
    negative_data,'FalseAlarmRate',0.41,'NumCascadeStages', 20, ...
    'TruePositiveRate', 0.6);

% I should do validation