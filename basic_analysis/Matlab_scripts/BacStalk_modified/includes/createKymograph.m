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

function createKymograph(src, ~)
data = getUIData(src);

toggleBusyPointer(data, 1)

trackID_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackID');
kymograph_trackStart_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackStart');
frameStart = str2double(kymograph_trackStart_h.String);
kymograph_trackEnd_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackEnd');
frameEnd = str2double(kymograph_trackEnd_h.String);
alignment_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_alignment');
measurement_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_measurement');
type_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_type');
type = type_h.Value;
orientateCells_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_orientCells');
orientateCells = orientateCells_h.Value;
colormap_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_colormap');
fullCell_h = findobj(data.mainFigure, 'Tag', 'cb_kymo_showFullCellWith');
fullCell = fullCell_h.Value;
backgroundSubtraction_h = findobj(data.mainFigure, 'Tag', 'cb_kymo_subtractBackground');
backgroundSubtraction = backgroundSubtraction_h.Value;
intensityNormalization_h = findobj(data.mainFigure, 'Tag', 'cb_kymo_intensityNormalization');
intensityNormalization = intensityNormalization_h.Value;
highlightMaxima_h = findobj(data.mainFigure, 'Tag', 'cb_kymo_highlightMaxima');
highlightMaxima = highlightMaxima_h.Value;
scaling_h = findobj(data.mainFigure, 'Tag', 'Scaling');
scaling = str2double(scaling_h.String);

sortMode = [];

alignment = alignment_h.Value;
trackID = str2num(trackID_h.String);

field = measurement_h.String{measurement_h.Value};

if type == 2
    maxStr = 'max_';
else
    maxStr = '';
end

fields = {['MedialAxisIntensity_', maxStr, field]; ...
    ['StalkIntensity_', field]};

% Compile the data
frames = [];
cellIDs = [];
for i = frameStart:frameEnd
    stats = data.frames(i).cells.Stats;
    trackIDs = [stats.TrackID];
    bud = [stats.Bud];
    cellDeleted = [stats.CellDeleted];
    
    idx = find(trackIDs == trackID & bud == false & cellDeleted == false)';
    
    if ~isempty(idx)
        frames = [frames; repmat(i, numel(idx), 1)];
        cellIDs = [cellIDs; idx];
    end
end


channel = field;

if ~isfield(data.frames(find(cellfun(@(x) ~isempty(x), {data.frames.cells}), 1)).cells.Stats, fields{1})
    msgbox(sprintf('The measurement field "%s" is not available.', fields{1}), 'Please note', 'warn', 'modal');
    toggleBusyPointer(data, 0)
    return;
end

[img_kymo, offset, ~, ticks] = compileData(src, [], frames, cellIDs, fields, fullCell, alignment, sortMode, channel, orientateCells, backgroundSubtraction, intensityNormalization);


h = figure('Name', sprintf('Kymograph: %s, trackID: %d', field, trackID));
h = addIcon(h);
h_ax = axes('Parent', h);
im_h = imagesc(img_kymo', 'Parent', h_ax, 'UserData', {cellIDs, src});
set(h_ax, 'NextPlot', 'add', 'clim', [min(img_kymo(:)) max(img_kymo(:))]);

plot(h_ax, h_ax.XLim, [offset, offset], '--', 'Color', 'r')

h_ax.YDir = 'normal';
ylabel(h_ax, 'Cell - stalk - budding cell (\mum)');

yLimits = ceil(round(size(img_kymo,2)*scaling)/10)*10;
set(h_ax, 'YTick', linspace(0, yLimits/scaling, 11), 'YTickLabel', linspace(0, yLimits, 11));
set(h_ax, 'XTick', ticks, 'XTickLabel', frames);

im_h.ButtonDownFcn = {@clickKymograph, linspace(0, yLimits/scaling, 11), linspace(0, yLimits, 11), ticks, frames};

xlabel(h_ax, 'Frame');

colormap(h_ax, colormap_h.String{colormap_h.Value});

% Highlight maxima
if highlightMaxima
    maxFields = {['MedialAxisIntensity_', maxStr, field]; ...
    ['StalkIntensity_', field]};

    dy = diff(ticks)/3;
    dy(end+1) = dy(end);
    
    maxDataInt = compileData(src, [], frames, cellIDs, maxFields, false, alignment, sortMode, channel, orientateCells, backgroundSubtraction, intensityNormalization);
    [~, brightestFoci] = max(maxDataInt, [], 2);
       
    for i = 1:numel(ticks)
        plot([ticks(i)-dy(i) ticks(i)+dy(i)], [brightestFoci(i) brightestFoci(i)], '-', 'Color', 'r')
    end
end

if fullCell
    axis(h_ax, 'equal');
    axis(h_ax, 'tight');
end

hb = colorbar(h_ax);
hb.Label.String = sprintf('%s (a.u.)', field);
hb.Label.Interpreter = 'none';
toggleBusyPointer(data, 0)

function clickKymograph(src, eventdata, y, y_label, x, x_label)

currentPoint = src.Parent.CurrentPoint(1,:);

[~, idx] = min(abs(x - currentPoint(1)));

axes_h = gca;

frame = x_label(idx);
frameIdx = find(str2num(axes_h.XTickLabel)==frame);
cellID = src.UserData{1}(frameIdx);

fprintf('Going to frame #%d, cell #%d\n', frame, cellID);
set(ancestor(src,'figure', 'toplevel'),'pointer','watch');
drawnow;
try
    displayImage(src.UserData{2}, [], frame);
    eventdata = [];
    clickCellTable(src.UserData{2}, eventdata, cellID);
    showCellDetectionTab(src.UserData{2}, []);
catch
    msgbox(sprintf('Cannot show cell #%d in frame #%d!', cellID, frame), 'Error', 'error', 'modal');
    fprintf('Error: cannot show cell\n');
end
set(ancestor(src,'figure', 'toplevel'),'pointer','arrow');



