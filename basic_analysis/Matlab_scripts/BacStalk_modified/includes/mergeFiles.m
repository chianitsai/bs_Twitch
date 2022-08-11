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

function mergeFiles(src, ~)

data = getUIData(src);

toggleBusy(src, [], 1)
drawnow;

% Load previous directory
if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
    load('directory.mat');
else
    directory = data.guiPath;
end

[filename1, directory1] = uigetfile('*.mat', 'Please select the 1st data-file', directory);

if filename1
    [filename2, directory2] = uigetfile('*.mat', 'Please select the 2nd data-file', directory);
    
    if filename2
        try
            % Try to load data
            data1 = load(fullfile(directory1, filename1));
            data2 = load(fullfile(directory2, filename2));
            
            if ~(isfield(data1, 'frames') && isfield(data1, 'params') && isfield(data1, 'settings') &&...
                    isfield(data2, 'frames') && isfield(data2, 'params') && isfield(data2, 'settings'))
                
                msgbox('Selected files are not valid!', 'Error', 'error', 'modal')
                toggleBusy(src, [], 0)
                return;
            end
            
            if numel(data1.settings.metadataNames) == numel(data2.settings.metadataNames) &&...
                 numel(data1.settings.channelNames) == numel(data2.settings.channelNames) 
                
                % Check metadata fields
                checkMetadataFields = numel(data1.settings.metadataNames);
                for i = 1:checkMetadataFields
                    if ~sum(strcmp(data1.settings.metadataNames{i}, data2.settings.metadataNames))
                        msgbox(sprintf('Metadata field "%s" of data #1 does not exist in data #2', data1.settings.metadataNames{i}), 'Error', 'error', 'modal')
                        toggleBusy(src, [], 0)
                        return;
                    end
                end
                
                % Check channels
                checkChannels = numel(data1.settings.channelNames);
                for i = 1:checkChannels
                    if ~sum(strcmp(data1.settings.channelNames{i}, data2.settings.channelNames))
                        msgbox(sprintf('Channel "%s" of data #1 does not exist in data #2', data1.settings.channelNames{i}), 'Error', 'error', 'modal')
                          toggleBusy(src, [], 0)
                        return;
                    end
                end
                
                % Merge frames
                dataNew.frames = [data1.frames data2.frames];

                dataNew.params = data1.params;
                dataNew.settings = data1.settings;
                
                % Merge input file tables
                dataNew.params.lb_files.String = [data1.params.lb_files.String; data2.params.lb_files.String];
                dataNew.params.tbl_files.Data = [data1.params.tbl_files.Data; data2.params.tbl_files.Data];
                
                % Remove trackID
                for i = 1:numel(dataNew.frames)
                    try
                        dataNew.frames(i).cells.Stats = rmfield(dataNew.frames(i).cells.Stats, 'TrackID');
                        dataNew.frames(i).cells.Stats = rmfield(dataNew.frames(i).cells.Stats, 'Parent');
                        dataNew.frames(i).cells.Stats = rmfield(dataNew.frames(i).cells.Stats, 'Grandparent');
                    end
                end
            else
                msgbox('Metadata/channel information does not match!', 'Error', 'error', 'modal')
                toggleBusy(src, [], 0)
                return;
                
            end
            
            
        catch
            msgbox('Files could not be merged!', 'Error', 'error', 'modal')
            toggleBusy(src, [], 0)
            return;
        end
        % Load previous directory
        if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
            load('directory.mat');
        else
            directory = data.guiPath;
        end
        
        [filename, directory] = uiputfile('*.mat', 'Save data', fullfile(directory, sprintf('%s_data_merged.mat', datestr(datetime, 'yyyy_mm_dd'))));
        
        % Save current directory
        if directory
            frames = dataNew.frames;
            params = dataNew.params;
            settings = dataNew.settings;
            
            save(fullfile(directory, filename), 'frames', 'params', 'settings');

        end
    end
end

toggleBusy(src, [], 0)