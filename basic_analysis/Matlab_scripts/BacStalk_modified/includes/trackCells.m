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

function trackCells(src, ~)
%data{1}: Parents, data{2}: actual cells, data{3}: Grandparents

data = getUIData(src);
frames = data.frames;
guiPath = data.guiPath;

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
cancelButton = findobj(data.mainFigure, 'Tag', 'pb_cancel');
cancelButton.Enable = 'on';

if ~isfield(frames, 'cells')
    return;
end

range = find(cellfun(@(x) ~isempty(x), {data.frames.cells}));

if numel(range) == 1
    msgbox('At least two processed frames are required for cell tracking.', 'Please note', 'warn', 'modal');
    return;
end

toggleBusyPointer(data, 1)
displayStatus(src, [], 'Cell tracking')

SearchRadius_h = findobj(data.mainFigure, 'Tag', 'SearchRadius');
SearchRadius = str2num(SearchRadius_h.String);
DilationWidth_h = findobj(data.mainFigure, 'Tag', 'DilationWidth');
DilationWidth = str2num(DilationWidth_h.String);

params.searchRadius = SearchRadius;
params.trackingStartNewSeries = 1;
params.trackCellsDilatePx = DilationWidth;
params.trackingStartNewSeries = 1;


updateWaitbar(data.axes.progress, 0.01)
 
fprintf('=== Cell tracking ===\n');

if sum(cellfun(@(x) ~isempty(x), strfind(fieldnames(data.frames), 'Position')))
    position = cell2mat({data.frames.Position});
else
    position = ones(numel(data.frames), 1);
end

positions = unique(position);
minTrackID = 0;

for i = 1:numel(positions)
    if ~iscancelled(guiPath)
        if isnumeric(position(1))
            range = find(position == positions(i));
        else
            range = find(strcmp(position, positions{i}));
        end
        
        % Removing frames with no cells
        nonEmptyCells = find(cellfun(@(x) ~isempty(x), {data.frames.cells}));
        range = intersect(range, nonEmptyCells);
        
        fprintf('Tracking pos #%d, frame %d - %d\n', i, range(1), range(end));

        try
            data = trackingAlgorithm(data, params, range, minTrackID);
        catch
            msgbox('Cell tracking failed. Please make sure that each frame is containing cells.', 'Please note', 'error', 'modal');
            cancelButton.Enable = 'off';
            updateWaitbar(data.axes.progress, 1)
            toggleBusyPointer(data, 0)
            return;
        end
        trackIDsAll = cellfun(@(x) [x.Stats.TrackID], {data.frames(range).cells}, 'UniformOutput', false);

        minTrackID = max([trackIDsAll{:}]);
    end
end

if iscancelled(guiPath)
    resetCancelButton(data);
    return
end

%% Generate track-table
updateTrackTables(data)

% Set flag to regenerate table upon click on the "Analysis"-tab
data.settings.generateAnalysisTable = true;

setUIData(data.mainFigure, data);

displayImage(src, [], round(slider_h.Value));

panelKymograph_h = findobj(data.mainFigure, 'Tag', 'panel_kymograph');
panelKymograph_h.Visible = 'On';

data.ui.fb(3).vb(1).analysis.sc.Heights = sum(data.ui.fb(3).vb(1).analysis.sc.Children.Heights)+20;

updateWaitbar(data.axes.progress, 1)
displayStatus(src, [], '')
cancelButton.Enable = 'off';
toggleBusyPointer(data, 0)