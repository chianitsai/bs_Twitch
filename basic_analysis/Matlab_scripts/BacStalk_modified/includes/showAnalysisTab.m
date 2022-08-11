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

function showAnalysisTab(src, ~)

data = getUIData(src);

if ~isfield(data, 'frames')
    data.ui.tabGroup.SelectedTab = data.ui.tabGroup.Children(1);
    msgbox('Please process images first!', 'No images processed', 'help', 'modal');
    return;
end

if ~sum(cellfun(@(x) ~isempty(x), {data.frames.cells}))
    data.ui.tabGroup.SelectedTab = data.ui.tabGroup.Children(2);
    msgbox('Please process images first!', 'No images processed', 'help', 'modal');
    return;
end

% Select tab
data.ui.tabGroup.SelectedTab = data.ui.tabGroup.Children(3);

setUIData(data.mainFigure, data);

if isfield(data.settings, 'generateAnalysisTable')
    if ~data.settings.generateAnalysisTable
        return
    end
end
data.settings.generateAnalysisTable = false;
        
toggleBusyPointer(data, 1)

%% Kymograph and Demograph
measurements = data.settings.channelNames;

popm_h = [findobj(data.mainFigure, 'Tag', 'popm_kymo_measurement');...
    findobj(data.mainFigure, 'Tag', 'popm_demo_measurement')];
for i = 1:numel(popm_h)
    popm_h(i).String = measurements;
    popm_h(i).Value = 1;
end

% Cell types to display
showCellType_h = findobj(data.mainFigure, 'Tag', 'popm_showCellType');
showCellType = showCellType_h.Value;

switch showCellType
    case 1
        alignmentOption = 1;
    case 2
        % Cells w/o stalks
        alignmentOption = 1;
    case 3
        % Cells w stalks
        alignmentOption = 2;
    case 4
        % Cells w stalks w/o budding cells
        alignmentOption = 2;
    case 5
        % Cells connected to budding cells
        alignmentOption = 3;
    case 6
        alignmentOption = 1;
    case 7
        alignmentOption = 1;
    case 8
        alignmentOption = 1;
end
popm_h = findobj(data.mainFigure, 'Tag', 'popm_demo_alignment');
for i = 1:numel(popm_h)
    popm_h(i).String = data.settings.algnmentOptions{alignmentOption};
    popm_h(i).Value = 1;
end
popm_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_alignment');
for i = 1:numel(popm_h)
    popm_h(i).String = data.settings.algnmentOptions{3};
    popm_h(i).Value = 1;
end
popm_h = findobj(data.mainFigure, '-regexp', 'Tag', 'sort');
for i = 1:numel(popm_h)
    popm_h(i).String = data.settings.sortOptions{alignmentOption};
    popm_h(i).Value = 1;
end


%% Populate the measurement popupmenues
fields = populateMeasurementSelectionElements(src, []);


%% Generate measurement fields
DetectStalks_h = findobj(data.mainFigure, 'Tag', 'x___HaveStalks');
DetectStalks = DetectStalks_h.Value;
DetectBuds_h = findobj(data.mainFigure, 'Tag', 'x___FormBuds');
DetectBuds = DetectBuds_h.Value;

if DetectStalks && DetectBuds
    fieldsInclude = {'CellID', 'Bud', 'Stalk', 'ConnectedWith', 'CellLength', 'StalkLength', 'TrackID'};
end
if DetectStalks && ~DetectBuds
    fieldsInclude = {'CellID', 'Stalk', 'CellLength', 'StalkLength', 'TrackID'};
end
if ~DetectStalks && ~DetectBuds
    fieldsInclude = {'CellID', 'CellLength', 'TrackID'};
end

% Add fields for fluorescence channels
channelNames = data.settings.channelNames;
if numel(channelNames) > 1
    for ch = 2:numel(channelNames)
        fieldsInclude = [fieldsInclude, sprintf('MeanCellIntensity_%s', channelNames{ch})];
    end
end

fieldsInclude = [{'Frame'}, fieldsInclude];
data.settings.measurementsFields = intersect(fieldsInclude, [fields', 'CellID'], 'stable');

%% Generate analysis table
data = createAnalysisTable(data);
setUIData(data.mainFigure, data);

set(findobj(data.mainFigure, 'Label','Export analysis-table to csv-file'), 'Enable', 'on');

toggleBusyPointer(data, 0)