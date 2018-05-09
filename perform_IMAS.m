function [ data_matches ] = perform_IMAS( im1, im2, opts)
%perform_IMAS Summary of this function goes here

% Usage 1: perform_IMAS( im1, im2)
% Usage 2: perform_IMAS( im1, im2, opts)

% opts is a struct and its possible fields are: applyfilter, covering, desc_type, compile

% apply_filter values corresponds to :
%   0. Apply no filter
%   1. Apply ORSA Fundamental
%   2. Apply ORSA Homography
%   3. Apply USAC Fundamental
%   4. Apply USAC Homography

%   possible covering values :
%   one element from 1.5:0.1:2 gives a near optimal covering
%   ...

% desc_type values corresponds to :
%   1. SIFT
%   2. SURF
%   11. RootSIFT
%   ...



% NOTES:
% Matlab handles differently images with respect to the c++ code!
% We need to use the image transpose

USAC = true;
OPENCV = false;
COMPILE = false;
applyfilter = 2;
desc_type = 11;
SHOWON = true;
covering = -1;
match_ratio = -1; % if supported for the specified descriptor

simu_tilts = 0;

% Input Parameters
switch nargin
    case 3
        if (~isstruct(opts))
            error('Optional parameter is not of type struct!');
        end
        names = fieldnames(opts);
        for i=1:length(names)
            name = names{i};
            switch name
                case 'compile'
                    COMPILE = opts.compile;
                case 'covering'
                    covering = opts.covering;
                case 'desc_type'
                    desc_type = opts.desc_type;
                case 'applyfilter'
                    applyfilter = opts.applyfilter;
                case 'psicell1'
                    PSICELL1 = opts.psicell1;
                    simu_tilts = simu_tilts + 1;
                case 'tvec1'
                    TVEC1 = opts.tvec1;
                    simu_tilts = simu_tilts + 1;
                case 'psicell2'
                    PSICELL2 = opts.psicell2;
                    simu_tilts = simu_tilts + 1;
                case 'tvec2'
                    TVEC2 = opts.tvec2;
                    simu_tilts = simu_tilts + 1;
                case 'showon'
                    SHOWON = opts.showon;
                case 'match_ratio'
                    match_ratio = opts.match_ratio;
            end
        end
    otherwise
        if (nargin~=2)
            error('Wrong number of input parameters!');
        end
end
data_matches = [];

if ( ndims(im1)~=2 | ndims(im2)~=2 )
    error('Only gray images are accepted');
end

currentfolder = pwd; % this saves the current folder
LIBRARYPATH = 'LD_LIBRARY_PATH= ';
if (simu_tilts==4)
    pavage2file(TVEC1,TVEC2,PSICELL1,PSICELL2);
    [status, ~] = system([LIBRARYPATH 'cp /tmp/pavage.txt ' currentfolder '/IMAS_cpp/2simu.csv']);
    disp('Generating covering file ...');
end

%setenv('OMP_NUM_THREADS', '4'); % use 4 threads for computing
cd ./IMAS_cpp/;
if ( (exist('IMAS_matlab')==0) || COMPILE )
    if ~OPENCV
        if (USAC)
            % IMAS standalone with USAC
            mex -v ...
                -I.  ...
                -I"/usr/include" -I"./libUSAC/config" -I"./libUSAC/utils" -I"./libUSAC/estimators" ...
                -I"/usr/local/include" -L"/usr/lib"...
                IMAS_matlab.cpp ...
                imas.cpp IMAS_coverings.cpp ...
                libSimuTilts/digital_tilt.cpp ...
                libSimuTilts/numerics1.cpp libSimuTilts/frot.cpp libSimuTilts/splines.cpp ...
                libSimuTilts/fproj.cpp libSimuTilts/library.cpp libSimuTilts/flimage.cpp ...
                libSimuTilts/filter.cpp ...
                libMatch/match.cpp ...
                libLocalDesc/surf/extract_surf.cpp libLocalDesc/surf/descriptor.cpp libLocalDesc/surf/image.cpp ...
                libLocalDesc/surf/keypoint.cpp libLocalDesc/surf/lib_match_surf.cpp ...
                libLocalDesc/sift/demo_lib_sift.cpp ...
                libOrsa/orsa_fundamental.cpp libOrsa/conditioning.cpp ...
                libOrsa/orsa_model.cpp libOrsa/fundamental_model.cpp ...
                libOrsa/homography_model.cpp ...
                libOrsa/orsa_homography.cpp ...
                libNumerics/numerics.cpp ...
                libUSAC/config/ConfigFileReader.cpp ...
                libUSAC/config/ConfigParams.cpp ...
                libUSAC/config/ConfigParamsFundmatrix.cpp ...
                libUSAC/config/ConfigParamsHomog.cpp ...
                libUSAC/utils/FundmatrixFunctions.cpp ...
                libUSAC/utils/HomographyFunctions.cpp ...
                libUSAC/utils/MathFunctions.cpp ...
                mex_and_omp.cpp ...
                CXXFLAGS="\$CXXFLAGS -D _NO_OPENCV=1 -D _USAC=1 -D _ACD=1 -fopenmp -fpermissive" LDFLAGS="\$LDFLAGS -fopenmp" ...
                CFLAGS="\$CFLAGS -fopenmp" ...
                -lconfig++ -llapack
        else
            mex -v ...
                -I.  ...
                -I"/usr/include" ...
                -I"/usr/local/include" -L"/usr/lib"...
                IMAS_matlab.cpp ...
                imas.cpp IMAS_coverings.cpp ...
                libSimuTilts/digital_tilt.cpp ...
                libSimuTilts/numerics1.cpp libSimuTilts/frot.cpp libSimuTilts/splines.cpp ...
                libSimuTilts/fproj.cpp libSimuTilts/library.cpp libSimuTilts/flimage.cpp ...
                libSimuTilts/filter.cpp ...
                libMatch/match.cpp ...
                libLocalDesc/surf/extract_surf.cpp libLocalDesc/surf/descriptor.cpp libLocalDesc/surf/image.cpp ...
                libLocalDesc/surf/keypoint.cpp libLocalDesc/surf/lib_match_surf.cpp ...
                libLocalDesc/sift/demo_lib_sift.cpp ...
                libOrsa/orsa_fundamental.cpp libOrsa/conditioning.cpp ...
                libOrsa/orsa_model.cpp libOrsa/fundamental_model.cpp ...
                libOrsa/homography_model.cpp ...
                libOrsa/orsa_homography.cpp ...
                libNumerics/numerics.cpp ...
                mex_and_omp.cpp ...
                CXXFLAGS="\$CXXFLAGS -fopenmp -fpermissive" LDFLAGS="\$LDFLAGS -fopenmp" ...
                CFLAGS="\$CFLAGS -fopenmp"
        end
        
    else
        % NOT DONE YET
        %OCV_INC_DIR='/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/include/opencv';
        %OCV2_INC_DIR='/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/include';
        %OCV_LIB_DIR ='/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/lib';
        %p = getenv('LD_LIBRARY_PATH'); p=[p,':',OCV_LIB_DIR]; setenv('LD_LIBRARY_PATH',p);
        mex -v -I. -I"/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/include/opencv" -I"/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/include" -I"/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/include/opencv2" -L"/home/rdguez-mariano/Sources/opencv_pluscontrib/build_qt/dest/lib"...
            IMAS_matlab.cpp ...
            IMAS_covering.cpp ...
            local_descriptor.cpp ...
            numerics1.cpp frot.cpp splines.cpp fproj.cpp ...
            library.cpp flimage.cpp filter.cpp ...
            libOrsa/orsa_fundamental.cpp libOrsa/conditioning.cpp...
            libOrsa/orsa_model.cpp libOrsa/fundamental_model.cpp ...
            libOrsa/homography_model.cpp libOrsa/orsa_homography.cpp...
            libNumerics/numerics.cpp mex_and_omp.cpp ...
            compute_IMAS_keypoints.cpp compute_IMAS_matches.cpp perform_IMAS.cpp ...
            CXXFLAGS="\$CXXFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"...
            CFLAGS="\$CFLAGS -fopenmp"...
            -lopencv_legacy -lopencv_imgproc -lopencv_core -lopencv_contrib -lopencv_ml  -lopencv_objdetect -lopencv_calib3d -lopencv_flann -lopencv_features2d -lopencv_video -lopencv_gpu -lopencv_xfeatures2d;
    end
    pause(0.2);
end
% Calling the Mex-Function
if ( (exist('IMAS_matlab')==3))
    data_matches = IMAS_matlab(double(im1'),double(im2'),applyfilter,covering, desc_type,simu_tilts==4, match_ratio);
    cd(currentfolder); % go back to the main directory
else
    error('Error: The Mex-Function IMAS_matlab was not compiled.')
end

if (SHOWON)
    plot_matches_in_images(im1,im2,data_matches);
    pause(0.2)
end
end