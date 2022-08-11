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

function createScatterplot(src, ~)

data = getUIData(src);
toggleBusyPointer(data, 1)

measurementX_h = findobj(data.mainFigure, 'Tag', 'popm_scatter_measurementX');
measurementY_h = findobj(data.mainFigure, 'Tag', 'popm_scatter_measurementY');

xScale_h = findobj(data.mainFigure, 'Tag', 'cb_scatter_scaleX');
yScale_h = findobj(data.mainFigure, 'Tag', 'cb_scatter_scaleY');

fields = {measurementX_h.String{measurementX_h.Value}...
    measurementY_h.String{measurementY_h.Value}};

indexes = getDataIndices(data);

frames = cell2mat(data.resultsTable(indexes,1));
cellIDs = cell2mat(data.resultsTable(indexes,2));

[compiledData, unit] = compileDataSimple(src, [], frames, cellIDs, fields);

% Query intensity data for focus-distance scatterplot
intensityColoredPlot = cellfun(@(x) ~isempty(x), strfind(fields, '_Distance'));
intData = repmat(lines(1), size(compiledData, 1), 1);
choice = 0;


if sum(intensityColoredPlot) == 1
    correspondingIntensityField = strrep(strrep(fields{intensityColoredPlot}, 'ToCellCenter', ''), '_Distance', '_Intensity');
    correspondingIntensityField = strrep(correspondingIntensityField, 'Custom_', '');
    intIdx = strfind(correspondingIntensityField, 'Intensity');
    correspondingIntensityField = correspondingIntensityField(1:intIdx+8);
    
    % ask for intensity colored plot
    choice = questdlg(sprintf('Color points according to the corresponding values in "%s"?', correspondingIntensityField),...
        'Color points?', ...
        'Yes','No','Cancel', 'Yes');
    switch choice
        case 'Yes'
            intData = compileDataSimple(src, [], frames, cellIDs, {correspondingIntensityField});
        case 'No'
            
        case 'Cancel'
            toggleBusyPointer(data, 0)
            return;
    end
    
end

h = figure('Name', sprintf('Scatterplot: %s vs. %s', fields{1}, fields{2}));
h = addIcon(h);
h_ax = axes('Parent', h);


sc_h = scatter(h_ax, compiledData(:,1), compiledData(:,2), repmat(36, 1, size(compiledData, 1)), intData, 'filled', 'ButtonDownFcn', @clickScatterplot, 'UserData', {src, frames, cellIDs});


if xScale_h.Value
    h_ax.XScale = 'log';
end

if yScale_h.Value
    h_ax.YScale = 'log';
end

box(h_ax, 'on');

xlabel(h_ax, [strrep(fields{1}, '_', ' '), unit{1}]);
ylabel(h_ax, [strrep(fields{2}, '_', ' '), unit{2}]);

if strcmp(choice, 'Yes')
    hb = colorbar(h_ax);
    hb.Label.String = sprintf('%s (a.u.)', strrep(correspondingIntensityField, '_', ' '));
    hb.Label.Interpreter = 'none';
    
    % Adapt colormap
    color = [0 0.4470 0.7410];
    cmap = flip([linspace(color(1), 0.9, 255)' linspace(color(2), 0.9, 255)' linspace(color(3), 1, 255)'], 1);
    colormap(h_ax, cmap);
end

toggleBusyPointer(data, 0)

function clickScatterplot(src, eventdata)

currentPoint = eventdata.IntersectionPoint;

[~, idx] = min(abs(src.XData - currentPoint(1)));

axes_h = gca;

frame = src.UserData{2}(idx);

cellID = src.UserData{3}(idx);

fprintf('Going to frame #%d, cell #%d\n', frame, cellID);
set(ancestor(src,'figure', 'toplevel'),'pointer','watch');
drawnow;
try
    eventdata = [];
    displayImage(src.UserData{1}, [], frame);
    clickCellTable(src.UserData{1}, eventdata, cellID);
    showCellDetectionTab(src.UserData{1}, []);
catch
    msgbox(sprintf('Cannot show cell #%d in frame #%d!', cellID, frame), 'Error', 'error', 'modal');
    fprintf('Error: cannot show cell\n');
end
set(ancestor(src,'figure', 'toplevel'),'pointer','arrow');

