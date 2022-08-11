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

function updateFileList(src, ~)

data = getUIData(src);


lb_files = findobj(data.mainFigure, 'tag', 'lb_files');
files = lb_files.String;

if isempty(files)
    return;
end

% Check if already processed file are there
if isfield(data, 'frames')
    if isfield(data.frames, 'cells')
        if sum(~cellfun(@isempty, {data.frames.cells}))
            choice = questdlg('Processed images found. If you update your file-table all processed data will be lost. Continue?',...
                'Really continue?', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                    % Do nothing
                case 'No'
                    return;
            end
        end
    end
end

toggleBusyPointer(data, 1)

files_noPath = cell(numel(files, 1));
for i = 1:numel(files)
    [~, file, ext] = fileparts(files{i});
    files_noPath{i} = [file, ext];
end

% Obtain all channels and metadata fields
channels = findobj(data.mainFigure, '-regexp', 'Tag', 'channelField');
channels = flip(channels);

metadata = findobj(data.mainFigure, '-regexp', 'Tag', 'metadataField');
metadata = flip(metadata);

% Assemble channels
table_files = {};
table_files_fullPath = {};
frames = []; % In this table all data is stored
channelNames = {};
metadataNames = {};

columnNames = [];
try
    filesPerChannel = zeros(numel(channels, 1));
    for i = 1:numel(channels)
        name_h = findobj(channels(i), '-regexp', 'Tag', 'channelName');
        name = name_h.String;
        if iscell(name)
            name = name{name_h.Value};
        end
        filenameContains_h = findobj(channels(i), '-regexp', 'Tag', 'filenameContains');
        filenameContains = filenameContains_h.String;
        
        % Find files matching criteria
        validFiles = find(cellfun(@(x) ~isempty(x), strfind(files_noPath, filenameContains)));
        filesPerChannel(i) = numel(validFiles);
        
        table_files_fullPath(1:numel(validFiles),i) = files(validFiles);
        table_files(1:numel(validFiles),i) = files_noPath(validFiles);
        columnNames{i} = name;
        
        % Initialize structure
        if isempty(frames)
            frames = cell2struct(files(validFiles)', name);
        else
            [frames.(name)] = files{validFiles};
        end
        channelNames{i} = name;
    end
catch
    toggleBusyPointer(data, 0)
    if diff(filesPerChannel) % Number of files per channel differ
        msgbox('The number of files per channel differs!', 'Error', 'error', 'modal')
    else
        msgbox(sprintf('Channel key word "%s" for channel "%s" was not found in filenames (the keyword is case-sensitive)!', filenameContains, name), 'Error', 'error', 'modal')
    end
    
    return;
end

% Update dropdown menu
set(findobj(data.mainFigure, 'Tag', 'popm_channel'), 'String', columnNames, 'Value', 1);

comlumIndex = size(table_files, 2);

try
    % Check metadata
    for i = 1:numel(metadata)
        name_h = findobj(metadata(i), '-regexp', 'Tag', 'metadataName');
        name = name_h.String;
        if iscell(name)
            name = name{name_h.Value};
        end
        filenameStart_h = findobj(metadata(i), '-regexp', 'Tag', 'filenameStart');
        filenameStart = filenameStart_h.String;
        
        filenameEnd_h = findobj(metadata(i), '-regexp', 'Tag', 'filenameEnd');
        filenameEnd = filenameEnd_h.String;
        
        isNumericData_h = findobj(metadata(i), '-regexp', 'Tag', 'isNumeric');
        isNumericData = isNumericData_h.Value;
        
        files_metadata = table_files(:,1)';
        
        extractedMetadata = cellfun(@(filename, startStr, endStr) ...
            filename(strfind(filename, startStr)+numel(startStr):...
            (strfind(filename, startStr)+numel(startStr))+...
            strfind(filename((strfind(filename, startStr)+numel(startStr)):end), endStr)-2),...
            files_metadata, repmat({filenameStart}, 1, numel(files_metadata)),...
            repmat({filenameEnd}, 1, numel(files_metadata)), 'UniformOutput', false);
        
        columnNames{comlumIndex+i} = name;
        
        % If data is numeric convert to double
        if isNumericData
            extractedMetadata = num2cell(cellfun(@str2num, extractedMetadata));
        end
        
        table_files(1:numel(extractedMetadata),comlumIndex+i) = extractedMetadata;
        table_idx(1:numel(extractedMetadata),i) = extractedMetadata;
        [frames.(name)] = extractedMetadata{:};
        metadataNames{i} = name;
    end
catch
    msgbox({'Please check you metadata-fields and make sure ', 'that "Start with" has an unique occurance per filename.'}, 'Error', 'help', 'modal')
end

if isempty(table_files)
    msgbox(sprintf('Channel key word "%s" was not found in filenames!', channelNames{1}), 'Error', 'error', 'modal')
    toggleBusyPointer(data, 0)
    return;
end

% Sort first by metadata field "Position" and then by "Time"
if sum(cellfun(@(x) ~isempty(x), strfind(fieldnames(frames), 'Position')))
    try
        if isnumeric(frames(1).Position)
            [~, idx] = sort(cell2mat({frames.Position}));
            
            % Sort all frames
            frames = frames(idx);
            
            table_files = table_files(idx,:);

            nPos = unique(cell2mat({frames.Position})); % The unique-command also sorts
            for p = 1:numel(nPos)
                pos = nPos(p);
                idxPos = find(cell2mat({frames.Position}) == pos);

                % If time is available sort for it
                if sum(cellfun(@(x) ~isempty(x), strfind(columnNames, 'Time')))
                    [~, idxTime] = sort(cell2mat({frames(idxPos).Time}));
                    
                    % Sort all frames
                    frames(idxPos) = frames(idxPos(idxTime));
                    
                    table_files(idxPos, :) = table_files(idxPos(idxTime),:);
                end
            end
        end
    catch
        msgbox('Position-metadata does not seem to be numeric!', 'Error', 'error', 'modal')
    end
else
    % Sort by time
    if sum(cellfun(@(x) ~isempty(x), strfind(fieldnames(frames), 'Time')))
        try
            [~, idx] = sort(cell2mat({frames.Time}));
            
            % Sort all frames
            frames = frames(idx);
            
            table_files = table_files(idx,:);
        end
    end
end

data.files.Data = table_files;
data.files.ColumnName = columnNames;
data.files.ColumnWidth = [repmat({250}, 1, numel(channels)) repmat({70}, 1, numel(metadata))];

frames = addColumnToStructure(frames, 'cells');
frames = addColumnToStructure(frames, 'tform');
frames = addColumnToStructure(frames, 'roi');

data.frames = frames;
data.settings.channelNames = channelNames;
data.settings.metadataNames = metadataNames;

% Check for timeseries
data.settings.isTimeseries = sum(cellfun(@(x) ~isempty(x), strfind(fieldnames(frames), 'Time')));

driftCorrection_h = findobj(data.mainFigure, 'Tag', 'DriftCorrection');
  
askForDriftCorrection = false;

if data.settings.isTimeseries
    if isnumeric(frames(1).Time)
        timeVec = cell2mat({frames.Time});
    else
        timeVec = {frames.Time};
    end
      
    if numel(unique(timeVec)) < numel(frames)
        if sum(cellfun(@(x) ~isempty(x), strfind(fieldnames(frames), 'Position')))
            if isnumeric(frames(1).Position)
                posVec = cell2mat({frames.Position});
            else
                posVec = {frames.Position};
            end
            if numel(unique(posVec)) * numel(unique(timeVec)) ~= numel(frames)
                msgbox('Still more then one image was aquired with the same time index...', 'Warning', 'warn', 'modal')
            else
                askForDriftCorrection = true;
            end
        else
            msgbox({'More then one image was aquired with the same time index.', 'You seem to have imaged multiple positions! Please add a metadata field to capture a position identifier.'}, 'Warning', 'warn', 'modal')
        end
    else
        askForDriftCorrection = false;
        driftCorrection_h.Value=1;
    end
    
else
    set(driftCorrection_h, 'Enable', 'off', 'Value', 0);
end
    
if askForDriftCorrection
    % Enable drift correction checkbox
      
    driftCorrection_h.Enable = 'on';
    
    if driftCorrection_h.Value == 0
        choice = questdlg('Time series detected. Do you want to enable automatic drift correction?',...
            'Drift correction?', ...
            'Yes','No','No');
        switch choice
            case 'Yes'
                driftCorrection_h.Value = 1;
            case 'No'
                driftCorrection_h.Value = 0;
        end
    end
end

% Update advanced settings
set(findobj(data.mainFigure, 'Tag', 'CellChannel'), 'String', channelNames, 'Value', 1);
set(findobj(data.mainFigure, 'Tag', 'StalkChannel'), 'String', channelNames, 'Value', 1);

setUIData(data.mainFigure, data);
% Update slider
updateSlider(data)
displayImage(src, [], 1)
restoreZoom(src, []);
updateROI(src, [], 'clear')

createJavaTable(data.tables.tableTracksSegmentation{2}, [], data.tables.tableTracksSegmentation{1}, {}, {'Cell were not tracked.'}, false, true);
createJavaTable(data.tables.tableSelectedTrack{2}, [], data.tables.tableSelectedTrack{1}, {}, {'Cell were not tracked.'}, false, true);
createJavaTable(data.tables.tableAnalysis{2}, [], data.tables.tableAnalysis{1}, {}, {'Cell were not segmented.'}, false, true);
createJavaTable(data.tables.tableStatistics{2}, [], data.tables.tableStatistics{1}, {}, {'Cell were not segmented.'}, false, true);

% Change size of visualization panel
data.ui.fb(3).vb(1).analysis.sc.Heights = sum(data.ui.fb(3).vb(1).analysis.sc.Children.Heights(1:3))+20;
    
% Remove scalebar
if isfield(data.ui, 'scalebar_line')
    if isvalid(data.ui.scalebar_line)
        delete(data.ui.scalebar);
        delete(data.ui.scalebar_line);
    end
end

% Enable tracking button
if data.settings.isTimeseries
    trackCells_h = findobj(data.mainFigure, 'Tag', 'pb_trackCells');
    trackCells_h.Enable = 'off';
end
% Enable tracking button
if data.settings.isTimeseries
    showTracks_h = findobj(data.mainFigure, 'Tag', 'pb_showTracks');
    showTracks_h.Enable = 'off';
end