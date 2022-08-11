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

function saveData(src, ~,directory)

data = getUIData(src);

% Load previous directory
% if isdeployed
%     pathstr = fileparts(which('directory.mat'));
%     load('directory.mat');
% else
%     if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
%         load('directory.mat');
%     else
%         directory = data.guiPath;
%     end
% end
filename='analyse_bacStalk'
% [filename, directory] = uiputfile('*.mat', 'Save data', fullfile(directory, sprintf('%s_data.mat', datestr(datetime, 'yyyy_mm_dd'))));

% Save current directory
if directory
    toggleBusy(src, [], 1)
    drawnow;
    
    if isdeployed
        save(fullfile(pathstr, 'directory.mat'), 'directory');
    else
        save(fullfile(data.guiPath, 'includes', 'directory.mat'), 'directory');
    end
    
    edits = findobj(data.mainFigure, 'Style', 'edit');
    for i = 1:length(edits)
        params.(edits(i).Tag).String = edits(i).String;
        params.(edits(i).Tag).Enable = edits(i).Enable;
    end
    pushbuttons = findobj(data.mainFigure, 'Style', 'pushbutton');
    for i = 1:length(pushbuttons)
        if ~isempty(pushbuttons(i).Tag)
            params.(pushbuttons(i).Tag).Enable = pushbuttons(i).Enable;
            params.(pushbuttons(i).Tag).UserData = pushbuttons(i).UserData;
        end
    end
    checkboxes = findobj(data.mainFigure, 'Style', 'checkbox');
    for i = 1:length(checkboxes)
        params.(checkboxes(i).Tag).Value = checkboxes(i).Value;
        params.(checkboxes(i).Tag).Enable = checkboxes(i).Enable;
    end
    popupmenus = findobj(data.mainFigure, 'Style', 'popupmenu');
    for i = 1:length(popupmenus)
        params.(popupmenus(i).Tag).Value = popupmenus(i).Value;
        params.(popupmenus(i).Tag).String = popupmenus(i).String;
        params.(popupmenus(i).Tag).Enable = popupmenus(i).Enable;
    end
    listboxes = findobj(data.mainFigure, 'Style', 'listbox');
    for i = 1:length(listboxes)
        params.(listboxes(i).Tag).Value = listboxes(i).Value;
        params.(listboxes(i).Tag).String = listboxes(i).String;
        params.(listboxes(i).Tag).Enable = listboxes(i).Enable;
    end
    tables = findobj(data.mainFigure, 'Type', 'uitable');
    for i = 1:length(tables)
        try
            params.(tables(i).Tag).Data = tables(i).Data;
            params.(tables(i).Tag).ColumnWidth = tables(i).ColumnWidth;
            params.(tables(i).Tag).ColumnName = tables(i).ColumnName;
            params.(tables(i).Tag).Enable = tables(i).Enable;
        end
    end
    
    % Remove PixelIdxLists of cells
    %cells = {frames.cells};
    
    %cells = cellfun(@(x) rmfield(x, 'PixelIdxList'), cells);
    
    if isfield(data, 'frames')
        frames = data.frames;
        settings = data.settings;
        save(fullfile(directory, filename), 'frames', 'params', 'settings');
    end
    
    toggleBusy(src, [], 0)
else
    disp('No folder selected');
    return;
end
