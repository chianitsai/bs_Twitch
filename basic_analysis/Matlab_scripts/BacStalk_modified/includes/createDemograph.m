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

function createDemograph(src, ~)
data = getUIData(src);
toggleBusyPointer(data, 1)

alignment_h = findobj(data.mainFigure, 'Tag', 'popm_demo_alignment');
measurement_h = findobj(data.mainFigure, 'Tag', 'popm_demo_measurement');
type_h = findobj(data.mainFigure, 'Tag', 'popm_demo_type');
type = type_h.Value;
orientateCells_h = findobj(data.mainFigure, 'Tag', 'popm_demo_orientCells');
orientateCells = orientateCells_h.Value;
plotRange_h = findobj(data.mainFigure, 'Tag', 'popm_demo_plotRange');
plotRange = plotRange_h.Value;
sortMode_h = findobj(data.mainFigure, 'Tag', 'popm_demo_sortMode');
sortMode = sortMode_h.String{sortMode_h.Value};
colormap_h = findobj(data.mainFigure, 'Tag', 'popm_demo_colormap');
intensityNormalization_h = findobj(data.mainFigure, 'Tag', 'cb_demo_intensityNormalization');
intensityNormalization = intensityNormalization_h.Value;
backgroundSubtraction_h = findobj(data.mainFigure, 'Tag', 'cb_demo_subtractBackground');
backgroundSubtraction = backgroundSubtraction_h.Value;
fullCell_h = findobj(data.mainFigure, 'Tag', 'cb_demo_showFullCellWith');
fullCell = fullCell_h.Value;
highlightMaxima_h = findobj(data.mainFigure, 'Tag', 'cb_demo_highlightMaxima');
highlightMaxima = highlightMaxima_h.Value;
scaling_h = findobj(data.mainFigure, 'Tag', 'Scaling');
scaling = str2double(scaling_h.String);


alignment = alignment_h.Value;

field = measurement_h.String{measurement_h.Value};

if type == 2
    maxStr = 'max_';
else
    maxStr = '';
end

fields = {['MedialAxisIntensity_', maxStr, field]; ...
    ['StalkIntensity_', field]};

indexes = getDataIndices(data);

frames = cell2mat(data.resultsTable(indexes,1));
cellIDs = cell2mat(data.resultsTable(indexes,2));

if plotRange == 2
   % Plot only selected data
   if isempty(data.resultsTable) || isempty(data.tables.tableAnalysis{1}.getSelectedRows)
        msgbox('No cell(s) selected.', 'Please note', 'warn', 'modal');
        toggleBusyPointer(data, 0)
        return;
   end
    
   frames = frames(data.tables.tableAnalysis{1}.getSelectedRows+1);
   cellIDs = cellIDs(data.tables.tableAnalysis{1}.getSelectedRows+1);
end


channel = field;

if ~isfield(data.frames(find(cellfun(@(x) ~isempty(x), {data.frames.cells}), 1)).cells.Stats, fields{1})
    msgbox(sprintf('The measurement field "%s" is not available.', fields{1}), 'Please note', 'warn', 'modal');
    toggleBusyPointer(data, 0)
    return;
end
        
[img_demo, offset, ~, ticks, sortIdx] = compileData(src, [], frames, cellIDs, fields, fullCell, alignment, sortMode, channel, orientateCells, backgroundSubtraction, intensityNormalization);

h = figure('Name', sprintf('Demograph: %s', field));
h = addIcon(h);
h_ax = axes('Parent', h);
im_h = imagesc(img_demo, 'Parent', h_ax, 'UserData', {cellIDs(sortIdx), frames(sortIdx), src});
set(h_ax, 'NextPlot', 'add', 'clim', [min(img_demo(:)) max(img_demo(:))], 'YDir', 'normal');

plot(h_ax, [offset, offset], h_ax.YLim, '--', 'Color', 'r')

h_ax.YDir = 'normal';
xlabel(h_ax, 'Cell - stalk - budding cell (\mum)');

if fullCell
    set(h_ax, 'YTick', ticks, 'YTickLabel', 1:numel(ticks));
    axis(h_ax, 'equal');
    axis(h_ax, 'tight');
end
ylabel(h_ax, '# Cell');


xLimits = ceil(round(size(img_demo,2)*scaling)/10)*10;

if size(img_demo,2)*scaling <= 3
    set(h_ax, 'XTick', linspace(0, xLimits/scaling, 21), 'XTickLabel', linspace(0, xLimits, 21));
else
    set(h_ax, 'XTick', linspace(0, xLimits/scaling, 11), 'XTickLabel', linspace(0, xLimits, 11));   
end

% Highlight maxima
if highlightMaxima
    maxFields = {['MedialAxisIntensity_', maxStr, field]; ...
    ['StalkIntensity_', field]};

    dy = diff(ticks)/3;
    dy(end+1) = dy(end);
    
    maxDataInt = compileData(src, [], frames, cellIDs, maxFields, false, alignment, sortMode, channel, orientateCells, backgroundSubtraction, intensityNormalization);
    [~, brightestFoci] = max(maxDataInt, [], 2);
       
    for i = 1:numel(ticks)
        plot([brightestFoci(i) brightestFoci(i)], [ticks(i)-dy(i) ticks(i)+dy(i)], '-', 'Color', 'r')
    end
end

im_h.ButtonDownFcn = {@clickDemograph, ticks, 1:numel(ticks), linspace(0, xLimits/scaling, 11), linspace(0, xLimits, 11)};

colormap(h_ax, colormap_h.String{colormap_h.Value});
hb = colorbar(h_ax);
hb.Label.String = sprintf('%s (a.u.)', field);
hb.Label.Interpreter = 'none';
toggleBusyPointer(data, 0)

function clickDemograph(src, eventdata, y, y_label, x, x_label)

currentPoint = src.Parent.CurrentPoint(1,:);

[~, idx] = min(abs(y - currentPoint(2)));
cellID = src.UserData{1}(idx);
frame = src.UserData{2}(idx);

fprintf('Going to frame #%d, cell #%d\n', frame, cellID);
set(ancestor(src,'figure', 'toplevel'),'pointer','watch');
drawnow;

try
    displayImage(src.UserData{3}, [], frame);
    clickCellTable(src.UserData{3}, [], cellID);
    showCellDetectionTab(src.UserData{3}, []);
catch
    msgbox(sprintf('Cannot show cell #%d in frame #%d!', cellID, frame), 'Error', 'error', 'modal');
    fprintf('Error: cannot show cell\n');
end
set(ancestor(src,'figure', 'toplevel'),'pointer','arrow');

