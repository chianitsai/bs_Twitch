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

function loadData(src, ~)

data = getUIData(src);

% Load previous directory
if isdeployed
    pathstr = fileparts(which('directory.mat'));
    load('directory.mat');
else
    if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
        load('directory.mat');
    else
        directory = data.guiPath;
    end
end

[filename, directory] = uigetfile('*.mat', 'Load data', directory);

% Save current directory
if directory
    toggleBusy(src, [], 1);
    drawnow;
    
    if isdeployed
        save(fullfile(pathstr, 'directory.mat'), 'directory');
    else
        save(fullfile(data.guiPath, 'includes', 'directory.mat'), 'directory');
    end
    
    dataLoaded = load(fullfile(directory, filename), 'frames', 'params', 'settings');
    
    if ~isfield(dataLoaded, 'frames') || ~isfield(dataLoaded, 'params') || ~isfield(dataLoaded, 'settings')
        msgbox('Invalid file!', 'Error', 'error', 'modal');
        toggleBusy(src, [], 0);
        return;
    end
    
    if isfield(dataLoaded.frames(1), 'PhaseContrast')
        if iscell(dataLoaded.frames(1).PhaseContrast)
            % Old format
            frames = struct;
            fNames = fieldnames(dataLoaded.frames);

            for i = 1:numel(fNames)
                [frames(1:numel(dataLoaded.frames.(fNames{i}))).(fNames{i})] = dataLoaded.frames.(fNames{i}){:};
            end
            dataLoaded.frames = frames;
        end
    end
    
    % Check if files still exist
    channels = dataLoaded.settings.channelNames;
    filesReplacedInListbox = false(numel(dataLoaded.params.lb_files.String), 1);
    filesReplacedInFrames = false(numel(channels), numel(dataLoaded.frames));
    
    for c = 1:numel(channels)

        removeFiles = false(numel(dataLoaded.frames), 1);
        
        
        for f = 1:numel(dataLoaded.frames)
            if ~exist(dataLoaded.frames(f).(channels{c}), 'file')
                choice = questdlg(sprintf('File "%s" could not be found. Would you like to relocate it?', dataLoaded.frames(f).(channels{c})),...
                    'File not found', ...
                    'Yes','Remove from list','Cancel','Yes');
                switch choice
                    case 'Yes'
                        [filePath, fileName, fileExt] = fileparts(dataLoaded.frames(f).(channels{c}));
                        [fileNameNew, directory] = uigetfile(['*', fileExt], 'Load data', fullfile(directory, [fileName, fileExt]));
                        if directory
                            dataLoaded.frames(f).(channels{c}) = fullfile(directory, fileNameNew);
                            filesReplacedInFrames(c, f) = true;
                            
                            for i = 1:numel(dataLoaded.params.lb_files.String)
                                fileNameNewListbox =...
                                    strrep(dataLoaded.params.lb_files.String{i}, ...
                                    fullfile(filePath, [fileName, fileExt]), ...
                                    fullfile(directory, fileNameNew));
                                
                                if ~strcmp(fileNameNewListbox, dataLoaded.params.lb_files.String{i})
                                    dataLoaded.params.lb_files.String{i} = fileNameNewListbox;
                                    filesReplacedInListbox(i) = true;
                                end
                            end
                            
                            % Replace in popupmenu
                            for i = 1:numel(dataLoaded.params.lb_files.String)
                                if ~filesReplacedInListbox(i)
                                    dataLoaded.params.lb_files.String{i} =...
                                        strrep(dataLoaded.params.lb_files.String{i}, ...
                                        [filePath, filesep], ...
                                        directory);
                                    filesReplacedInListbox(i) = true;
                                end
                            end
                            
                            % Replace directory for all files
                            for c2 = 1:numel(channels)
                                for f2 = 1:numel(dataLoaded.frames)
                                    if ~filesReplacedInFrames(c2, f2)
                                        dataLoaded.frames(f2).(channels{c2}) = strrep(dataLoaded.frames(f2).(channels{c2}),...
                                            [filePath, filesep], directory);
                                        filesReplacedInFrames(c2, f2) = true;
                                    end
                                end
                            end
                        else
                            toggleBusy(src, [], 0)
                            return;
                        end
                        
                    case 'Remove from list'
                        removeFiles(f) = true;
                    case 'Cancel'
                        toggleBusy(src, [], 0)
                        return;
                end
                
                
            end
        end
        % Remove files
        dataLoaded.frames(removeFiles) = [];
        if isempty(dataLoaded.frames)
            msgbox('All files removed, no data left to load!', 'Error', 'error', 'modal');
            toggleBusy(src, [], 0)
            return;
        end
        
    end
    
    % Delete channel/metadata boxes
    delete(findobj(data.mainFigure, '-regexp', 'Tag', 'channelField'));
    delete(findobj(data.mainFigure, '-regexp', 'Tag', 'metadataField'));
    
    % Add channel boxes
    for i = 1:numel(dataLoaded.settings.channelNames)
        addChannel(data.ui.channelBox);
    end
    % Add metadata boxes
    for i = 1:numel(dataLoaded.settings.metadataNames)
        addMetadata(data.ui.metadataBox);
    end
        
    data.frames = dataLoaded.frames;
    
    settingsFields = fieldnames(dataLoaded.settings);
    settingsFields = setdiff(settingsFields, {'algnmentOptions', 'sortOptions'});
    for i = 1:numel(settingsFields)
        data.settings.(settingsFields{i}) = dataLoaded.settings.(settingsFields{i});
    end
    
    params = dataLoaded.params;
    
    edits = findobj(data.mainFigure, 'Style', 'edit');
    for i = 1:length(edits)
        try
            edits(i).String = params.(edits(i).Tag).String;
            edits(i).Enable = params.(edits(i).Tag).Enable;
        catch
            fprintf('Cannot set "%s"\n', edits(i).Tag);
        end
    end
    pushbuttons = findobj(data.mainFigure, 'Style', 'pushbutton');
    for i = 1:length(pushbuttons)
        try
            if ~isempty(pushbuttons(i).Tag)
                pushbuttons(i).UserData = params.(pushbuttons(i).Tag).UserData;
                pushbuttons(i).Enable = params.(pushbuttons(i).Tag).Enable;
                c = pushbuttons(i).UserData;
                if numel(c) == 3 && max(c) <= 1 && min(c) >= 0
                    pushbuttons(i).BackgroundColor = c;
                end
            end
        catch
            fprintf('Cannot set "%s"\n', pushbuttons(i).Tag);
        end
    end
    checkboxes = findobj(data.mainFigure, 'Style', 'checkbox');
    for i = 1:length(checkboxes)
        try
            checkboxes(i).Value = params.(checkboxes(i).Tag).Value;
            checkboxes(i).Enable = params.(checkboxes(i).Tag).Enable;
        catch
            fprintf('Cannot set "%s"\n', checkboxes(i).Tag);
        end
    end
    popupmenus = findobj(data.mainFigure, 'Style', 'popupmenu');
    for i = 1:length(popupmenus)
        try
            popupmenus(i).Value = params.(popupmenus(i).Tag).Value;
            popupmenus(i).String = params.(popupmenus(i).Tag).String;
            popupmenus(i).Enable = params.(popupmenus(i).Tag).Enable;
        catch
            dispError = true;
            availableFields = fieldnames(params);
            if sum(cellfun(@(x) ~isempty(x), strfind(availableFields, 'ImageBackground'))) % For compatibility with versions <= 1.5
                if strcmp(popupmenus(i).Tag, 'CellBackground') || strcmp(popupmenus(i).Tag, 'StalkBackground')
                    popupmenus(i).Value = params.ImageBackground.Value;
                    popupmenus(i).String = params.ImageBackground.String;
                    popupmenus(i).Enable = params.ImageBackground.Enable;
                    dispError = false;
                end
            end
            if dispError
                fprintf('Cannot set "%s"\n', popupmenus(i).Tag);
            end
        end
    end
    listboxes = findobj(data.mainFigure, 'Style', 'listbox');
    for i = 1:length(listboxes)
        % Don't update sorting & alignment options
        if ~isempty(strfind(lower(listboxes(i).Tag), 'align')) || ~isempty(strfind(lower(listboxes(i).Tag), 'sort'))
            continue;
        end
        try
            listboxes(i).Value = params.(listboxes(i).Tag).Value;
            listboxes(i).String = params.(listboxes(i).Tag).String;
            listboxes(i).Enable = params.(listboxes(i).Tag).Enable;
        catch
            fprintf('Cannot set "%s"\n', listboxes(i).Tag);
        end
    end
    tables = findobj(data.mainFigure, 'Type', 'uitable');
    for i = 1:length(tables)
        try
            tables(i).Data = params.(tables(i).Tag).Data;
            tables(i).ColumnWidth = params.(tables(i).Tag).ColumnWidth;
            tables(i).ColumnName = params.(tables(i).Tag).ColumnName;
            tables(i).Enable = params.(tables(i).Tag).Enable;
        catch
            %fprintf('Cannot set "%s"\n', tables(i).Tag);
        end
    end
    
    data.settings.previousImage = [];
    data.settings.generateAnalysisTable = true;
    
    setUIData(data.mainFigure, data);
    showInputTab(src, []);
   
    updateSlider(data)
    displayImage(src, [], 1)
    data = getUIData(data.mainFigure);
    
    restoreZoom(src, []);
    
    createJavaTable(data.tables.tableTracksSegmentation{2}, [], data.tables.tableTracksSegmentation{1}, {}, {'Cell were not tracked.'}, false, true);
    createJavaTable(data.tables.tableSelectedTrack{2}, [], data.tables.tableSelectedTrack{1}, {}, {'Cell were not tracked.'}, false, true);
    createJavaTable(data.tables.tableAnalysis{2}, [], data.tables.tableAnalysis{1}, {}, {'Cell were not segmented.'}, false, true);
    createJavaTable(data.tables.tableStatistics{2}, [], data.tables.tableStatistics{1}, {}, {'Cell were not segmented.'}, false, true);
    
    
    cells = {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells};
    if ~isempty(cells)
        if ~isempty(find(strcmp(fieldnames(cells{1}.Stats), 'TrackID')))
            updateTrackTables(data);
            data.ui.fb(3).vb(1).analysis.sc.Heights = sum(data.ui.fb(3).vb(1).analysis.sc.Children.Heights)+20;
            panelKymograph_h = findobj(data.mainFigure, 'Tag', 'panel_kymograph');
            panelKymograph_h.Visible = 'On';
        end
    end
    
    % Delete displayed track overlays
    delete(findobj(data.axes.main, '-regexp', 'Tag', 'track'));
    
    toggleBusy(src, [], 0)
    setUIData(data.mainFigure, data);
else
    return;
end
