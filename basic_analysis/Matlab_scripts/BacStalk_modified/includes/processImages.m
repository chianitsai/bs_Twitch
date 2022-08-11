%%
% BacStalk
%
% Copyright (c) 2018 Raimo Hartmann & Muriel van Teeseling <bacstalk@gmail.com>
% Copyright (c) 2018 Drescher-lab, Max Planck Institute for Terrestrial Microbiology, Marburg, Germany
% Copyright (c) 2018 Thanbichler-lab, Philipps Universitaet, Marburg, Germany
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%

function processImages(src, ~, range)

data = getUIData(src);

guiPath = data.guiPath;

validParameters = true;

% Assign variables and call all parameter callbacks to check inputs
CellSize_h = findobj(data.mainFigure, 'Tag', 'CellSize');
if ~checkInput(CellSize_h); validParameters = false; end
    CellSize = str2num(CellSize_h.String);
UseBinaryMasks_h = findobj(data.mainFigure, 'Tag', 'UseBinaryMasks');
UseBinaryMasks = UseBinaryMasks_h.Value;
MinCellSize_h = findobj(data.mainFigure, 'Tag', 'MinCellSize');
if ~checkInput(MinCellSize_h); validParameters = false; end
MinCellSize = str2num(MinCellSize_h.String);
DetectStalks_h = findobj(data.mainFigure, 'Tag', 'x___HaveStalks');
DetectStalks = DetectStalks_h.Value;
DetectBuds_h = findobj(data.mainFigure, 'Tag', 'x___FormBuds');
DetectBuds = DetectBuds_h.Value;
MinStalkLength_h = findobj(data.mainFigure, 'Tag', 'MinStalkLength');
if ~checkInput(MinStalkLength_h); validParameters = false; end
MinStalkLength = str2num(MinStalkLength_h.String);
StalkScreeningLength_h = findobj(data.mainFigure, 'Tag', 'StalkScreeningLength');
if ~checkInput(StalkScreeningLength_h); validParameters = false; end
StalkScreeningLength = str2num(StalkScreeningLength_h.String);
StalkScreeningWidth_h = findobj(data.mainFigure, 'Tag', 'StalkScreeningWidth');
if ~checkInput(StalkScreeningWidth_h); validParameters = false; end
StalkScreeningWidth = str2num(StalkScreeningWidth_h.String);
CellExpansionWidth_h = findobj(data.mainFigure, 'Tag', 'CellExpansionWidth');
if ~checkInput(CellExpansionWidth_h); validParameters = false; end
CellExpansionWidth = str2num(CellExpansionWidth_h.String);
StalkSensitivity_h = findobj(data.mainFigure, 'Tag', 'StalkSensitivity');
if ~checkInput(StalkSensitivity_h); validParameters = false; end
StalkSensitivity = str2num(StalkSensitivity_h.String);
StalkRigidity_h = findobj(data.mainFigure, 'Tag', 'MaxStalkFlexibility');
if ~checkInput(StalkRigidity_h); validParameters = false; end
StalkRigidity = str2num(StalkRigidity_h.String);
ExcludeCellsCloseBy_h = findobj(data.mainFigure, 'Tag', 'ExcludeCellsCloseBy');
ExcludeCellsCloseBy = ExcludeCellsCloseBy_h.Value;
Debugging_h = findobj(data.mainFigure, 'Tag', 'Debugging');
Debugging = Debugging_h.Value;
CellChannel_h = findobj(data.mainFigure, 'Tag', 'CellChannel');
CellChannel = CellChannel_h.Value;
CellBackground_h = findobj(data.mainFigure, 'Tag', 'CellBackground');
CellBackground = CellBackground_h.String{CellBackground_h.Value};
StalkChannel_h = findobj(data.mainFigure, 'Tag', 'StalkChannel');
StalkChannel = StalkChannel_h.Value;
StalkBackground_h = findobj(data.mainFigure, 'Tag', 'StalkBackground');
StalkBackground = StalkBackground_h.String{StalkBackground_h.Value};

if ~validParameters
    return;
end

% Determine range
N = numel(data.frames);
slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
switch range
    case 'selected'
        imIdx = round(slider_h.Value);
    case 'all'
        imIdx = 1:N;
        
        % Check crop range
        if ~isempty(data.frames(1).roi) && isempty(data.frames(end).roi)
            choice = questdlg('Do you want to extend the ROI of frame 1 to all other frames?',...
                'Extend ROI?', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                    for i = 2:numel(data.frames)
                        data.frames(i).roi = data.frames(1).roi;
                    end
                otherwise
                    % Do nothing
            end
            setUIData(data.mainFigure, data);
        end
end

cancelButton = findobj(data.mainFigure, 'Tag', 'pb_cancel');
cancelButton.Enable = 'on';

% Get list of all disabled popupmenues, listboxes, edits, slider, menues, checkboxes and pushbuttons
UIElements = num2cell([findobj(data.mainFigure, 'Style', 'popupmenu'); findobj(data.mainFigure, 'Style', 'listbox'); findobj(data.mainFigure, 'Style', 'slider'); findobj(data.mainFigure, 'Style', 'edit');...
    findobj(data.mainFigure, 'Style', 'pushbutton'); findobj(data.mainFigure, 'Type', 'uimenu'); findobj(data.mainFigure, 'Style', 'checkbox')]);
ElementState = cellfun(@(x) x.Enable, UIElements, 'UniformOutput', false);
% Disable all elements
for i = 1:numel(UIElements)
    UIElements{i}.Enable = 'off';
end

% Enable cancel button
data.ui.cb.Enable = 'on';
drawnow;

toggleBusyPointer(data, 1)

% Set flag to regenerate table upon click on the "Analysis"-tab
data.settings.generateAnalysisTable = true;

warning off;
delete(timerfindall('Tag', 'timer_progresBar'));
warning on;

% Check for drift correction
DriftCorrection_h = findobj(data.mainFigure, 'Tag', 'DriftCorrection');
if DriftCorrection_h.Value
    performDriftCorrection = false;
    if ~isfield(data.frames, 'tform')
        performDriftCorrection = false;
    else
        if sum(cellfun(@(x) isempty(x),  {data.frames.tform}))
            performDriftCorrection = false;
        end
    end
else
    performDriftCorrection = false;
end

% Check if parallel processing is enabled
doParallel_h = findobj(data.mainFigure, 'Tag', 'ParallelProcessing');
if doParallel_h.Value && ((N > 1 && performDriftCorrection) || (numel(imIdx) > 1))
    myCluster = parcluster('local');
    nWorkers = myCluster.NumWorkers;
    
    % Start parallel pool
    displayStatus(src, [], 'Starting parallel pool (please wait)')
    drawnow;
    gcp;
else
    nWorkers = 0;
end

ax_h_progress = data.axes.progress;

% Perform drift correction
if performDriftCorrection
    displayStatus(src, [], 'Drift-correction')
    fprintf('=== Drift correction ===\n');
    %% Calculate image drift
    tform_xy = cell(N, 1);
    
    tform_xy{1} = affine2d;
    imageNames = {data.frames.(data.settings.channelNames{1})};
    
    if sum(cellfun(@(x) ~isempty(x), strfind(fieldnames(data.frames), 'Position')))
        position = cell2mat({data.frames.Position});
    else
        position = ones(numel(imageNames), 1);
    end
    
    hbar = parfor_progressbar(N,ax_h_progress);
    
    parfor (t = 2:N, nWorkers)
        if ~iscancelled(guiPath)
            %fprintf('   - aligning image %d/%d\n', t, N);
            tform_xy{t} = affine2d;
            if isnumeric(position(1))
                samePos = position(t-1) == position(t);
            else
                samePos = strcmp(position{t-1}, position{t});
            end
            
            if samePos % Same position
                img_fixed = imread(imageNames{t-1});
                if size(img_fixed, 3) > 1
                    img_fixed = sum(img_fixed, 3);
                end
                img_moving = imread(imageNames{t});
                if size(img_moving, 3) > 1
                    img_moving = sum(img_moving, 3);
                end
                    
                usfac = 10;
                output = dftregistration(fft2(single(img_fixed)),fft2(single(img_moving)),usfac);
                
                tform_xy{t}.T(3,1:2) = [output(4), output(3)];
            else
                tform_xy{t}.T(3,1:2) = [0 0]; % No registration between different positions
            end
            
            fprintf('[WORKER %d] Image %d of %d, shift: [%.1f, %.1f] px\n', t, t, N, tform_xy{t}.T(3,1), tform_xy{t}.T(3,2));
            
            hbar.iterate(1);
        end
    end
    close(hbar);
    
    if iscancelled(guiPath)
        msgbox('Processing cancelled during drift correction.', 'Cancelled', 'help', 'modal');
        resetCancelButton(data);
        toggleBusyPointer(data, 0)
        % Revert all uielement states
        for i = 1:numel(UIElements)
            UIElements{i}.Enable = ElementState{i};
        end
        cancelButton.Enable = 'off';
        displayStatus(src, [], '')
        return
    end
    
    %fprintf('  Calculated shifts (data stored in "tform_xy"):\n');
    for i = 2:N
        if isnumeric(position(1))
            samePos = position(i-1) == position(i);
        else
            samePos = strcmp(position{i-1}, position{i});
        end
        
        if samePos
            tform_xy{i}.T(3,1:2) = tform_xy{i}.T(3,1:2) + tform_xy{i-1}.T(3,1:2);
        else
            tform_xy{i}.T(3,1:2) = [0 0]; % New position
        end
        %fprintf('   - image %d/%d, shift: [x, y] = [%.2f, %.2f] px\n', i, N, tform_xy{i}.T(3,1), tform_xy{i}.T(3,2));
    end
    [data.frames.tform] = tform_xy{:};
    
    % Save data even if segmentation is cancelled
    setUIData(data.mainFigure, data);
end


if Debugging && nWorkers>0
    msgbox('Image processing cannot be done with multiple workers because the debugging mode is enabled.', 'Please note', 'help', 'modal');
    nWorkers = 0;
end

cells = cell(N, 1);
displayStatus(src, [], 'Cell/Stalk segmentation')
fprintf('=== Cell/Stalk segmentation ===\n');

if numel(imIdx) == 1
    nWorkers = 0;
end
frames = data.frames;
hbar = parfor_progressbar(numel(imIdx), ax_h_progress);
channelNames = data.settings.channelNames;
settings = data.settings;


parfor (i = 1:numel(imIdx), nWorkers)
    if ~iscancelled(guiPath)
        fprintf('[WORKER %d] Started\n', i);
        tic
        
        imgFluo = [];
       
        idx = imIdx(i);
        
        % Get ROI
        if isfield(frames, 'roi')
            if ~isempty(frames(idx).roi)
                ROI = frames(idx).roi;
                if ~isnumeric(ROI)
                    ROI = str2num(ROI);
                end
            else
                ROI = [];
            end
        else
            ROI = [];
        end
                
        % Load images
        img = cell(1, numel(channelNames));
        for ch = 1:numel(channelNames)
            img{ch} = imread(frames(idx).(channelNames{ch}));
            if size(img{ch}, 3) > 1
                img{ch} = sum(img{ch}, 3);
            end
        end
        
        % Check sizes
        sizes = cellfun(@size, img, 'UniformOutput', false);
        if numel(img) > 1
            if sum(diff(cellfun(@(x) x(1), sizes))) || sum(diff(cellfun(@(x) x(2), sizes)))
                warning('The sizes of the different channel images for image set "%d" do not match!', i);
                continue;
            end
        end
        channelName_forFieldnames = channelNames;
        
        % Please note: Scaling = 1, because the scaling will be applied
        % afterwards
        if isempty(frames(1).tform)
            tform = [];
        else
            tform = frames(idx).tform;
        end

        cells{i} = segmentStalkedCells(img, ...
            'ROI', ROI, ...
            'scaling', 1, ...
            'cellSize', CellSize, ...
            'minCellSize', MinCellSize, ...
            'detectStalks', DetectStalks, ...
            'minStalkLength', MinStalkLength, ...
            'stalkScreeningLength', StalkScreeningLength, ...
            'stalkScreeningWidth', StalkScreeningWidth, ...
            'cellExpansionWidth', CellExpansionWidth, ...
            'stalkSensitivity', StalkSensitivity, ...
            'stalkRigidity', StalkRigidity, ...
            'tform', tform, ...
            'expandMedialAxis', true, ...
            'channelName', channelName_forFieldnames, ...
            'detectBuds', DetectBuds, ...
            'excludeCellsCloseBy', ExcludeCellsCloseBy, ...
            'debugging', Debugging, ...
            'worker', i, ...
            'cellBackground', CellBackground, ...
            'stalkBackground', StalkBackground, ...
            'cellChannel', CellChannel, ...
            'stalkChannel', StalkChannel, ...
            'useBinaryMasks', UseBinaryMasks);

        % Add metadata entries
        if isfield(settings, 'metadataNames') && cells{i}.NumObjects > 0
            for m = 1:numel(settings.metadataNames)
                 meta = repmat({frames(i).(settings.metadataNames{m})}, 1, numel(cells{i}.Stats));
                [cells{i}.Stats.(settings.metadataNames{m})] = meta{:};
            end
        end
        
        fprintf('[WORKER %d] Finished. Elapsed time: %.1f s\n', i, toc);
        if ~iscancelled(guiPath)
            hbar.iterate(1);
        end
    end
end
close(hbar);

if iscancelled(guiPath)
    msgbox(sprintf('Processing cancelled (%d of %d images processed).', sum(cellfun(@(x) ~isempty(x), cells)), numel(imIdx)), 'Cancelled', 'help', 'modal');
    resetCancelButton(data);
end

% Revert all uielement states
for i = 1:numel(UIElements)
    UIElements{i}.Enable = ElementState{i};
end

for i = 1:numel(imIdx)
    idx = imIdx(i);
    if cells{i}.NumObjects > 0
        data.frames(idx).cells = cells{i};
    else
        data.frames(idx).cells = [];
    end
end

% Enable tracking button
if data.settings.isTimeseries
    trackCells_h = findobj(data.mainFigure, 'Tag', 'pb_trackCells');
    trackCells_h.Enable = 'on';
end

%assignin('base', 'data', data);
panelKymograph_h = findobj(data.mainFigure, 'Tag', 'panel_kymograph');
panelKymograph_h.Visible = 'Off';

% In Analysis tab
createJavaTable(data.tables.tableSelectedTrack{2}, [], data.tables.tableSelectedTrack{1}, {}, {'Cell were not tracked.'});

% In Cell/Stalk detection
createJavaTable(data.tables.tableTracksSegmentation{2}, [], data.tables.tableTracksSegmentation{1}, {}, {'Cell were not tracked.'});

data.settings.previousImage = [];

setUIData(data.mainFigure, data);

drawnow;

displayImage(src, [], imIdx(1));
updateWaitbar(data.axes.progress, 1)
displayStatus(src, [], '')
cancelButton.Enable = 'off';
toggleBusyPointer(data, 0)