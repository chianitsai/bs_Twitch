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

function cells = plotOverlays(data, cells)

% Get colors
colors = struct;
text_color_h = findobj(data.mainFigure, 'tag', 'TextColor');
colors.text_color = text_color_h.UserData;
cellOutline_color_h = findobj(data.mainFigure, 'tag', 'CellOutlineColor');
colors.cellOutline_color = cellOutline_color_h.UserData;
medialAxis_color_h = findobj(data.mainFigure, 'tag', 'MedialAxisColor');
colors.medialAxis_color = medialAxis_color_h.UserData;
stalk1_color = findobj(data.mainFigure, 'tag', 'StalkColor1');
colors.stalk1_color = stalk1_color.UserData;
stalk2_color = findobj(data.mainFigure, 'tag', 'StalkColor2');
colors.stalk2_color = stalk2_color.UserData;
deletedObject_color_h = findobj(data.mainFigure, 'tag', 'DeletedObjectColor');
colors.deletedObject_color = deletedObject_color_h.UserData;
cellPole_color_h = findobj(data.mainFigure, 'tag', 'CellPoleColor');
colors.cellPole_color = cellPole_color_h.UserData;

fontSize_h = findobj(data.mainFigure, 'tag', 'OverlayFontSize');
fontSize = str2double(fontSize_h.String);
lineWidth_h = findobj(data.mainFigure, 'tag', 'LineWidth');
lineWidth = str2double(lineWidth_h.String);
showTrackID_h = findobj(data.mainFigure, 'tag', 'ShowTrackID');
showTrackID = showTrackID_h.Value;

plotResolution_h = findobj(data.mainFigure, 'tag', 'PlotResolution');
plotResolution = str2double(plotResolution_h.String);

h_ax = data.axes.main;

if isfield(cells, 'Handles')
    handles = cells.Handles;
    
    if ~isfield(handles, 'undoDeleteCellData')
        handles = struct('cellOutline', [], 'medialAxis', [], 'stalk', [], 'label', [], 'undoDeleteCell', [], 'undoDeleteStalk', [],...
        'undoDeleteCellData', [], 'undoDeleteStalkData', [], 'medialAxisOrientation', []);
    
        for c = 1:cells.NumObjects
            handles(c) = plotCell(h_ax, c, cells.Stats(c), colors, fontSize, lineWidth, showTrackID, plotResolution, cells.Stats, []);
        end
    else
    
        % Transfer already existing undo-data
        for c = 1:cells.NumObjects
            handles(c) = plotCell(h_ax, c, cells.Stats(c), colors, fontSize, lineWidth, showTrackID, plotResolution, cells.Stats, handles(c));
        end
    end
    
else
    handles = struct('cellOutline', [], 'medialAxis', [], 'stalk', [], 'label', [], 'undoDeleteCell', [], 'undoDeleteStalk', [],...
        'undoDeleteCellData', [], 'undoDeleteStalkData', [], 'medialAxisOrientation', []);
    
    for c = 1:cells.NumObjects
        handles(c) = plotCell(h_ax, c, cells.Stats(c), colors, fontSize, lineWidth, showTrackID, plotResolution, cells.Stats, []);
    end
end



cells.Handles = handles;

function handles = plotCell(axes_handle, cellId, singleCellStats, colors, fontSize, lineWidth, showTrackID, plotResolution, Stats, handles)
if isempty(handles)
    handles = struct('cellOutline', [], 'medialAxis', [], 'stalk', [], 'label', [], 'undoDeleteCell', [], 'undoDeleteStalk', [],...
        'undoDeleteCellData', [], 'undoDeleteStalkData', [], 'medialAxisOrientation', []);
else
    handles.cellOutline = [];
    handles.medialAxis = [];
    handles.stalk = [];
    handles.label = [];
    handles.undoDeleteCell = [];
    handles.medialAxisOrientation = [];
    handles.undoDeleteStalk = [];
end

% Plot stalk
if singleCellStats.Stalk
    % Plot Connection
    if ~isempty(singleCellStats.ConnectedWith)
        stalkColor = colors.stalk2_color;
    else
        stalkColor = colors.stalk1_color;
    end
    try
        handles.stalk = plot(axes_handle, [singleCellStats.StalkCoordinates(1:plotResolution:end,2); singleCellStats.StalkCoordinates(end, 2)], [singleCellStats.StalkCoordinates(1:plotResolution:end,1); singleCellStats.StalkCoordinates(end,1)],...
            'Color', stalkColor, 'ButtonDownFcn', {@deleteObject, 'stalk', cellId}, 'Tag', 'cell_stalk', 'LineWidth', lineWidth);
    catch
        sprintf('Stalk of cell #%d could not be plotted.', cellId);
    end
end

% Plot cell outline
if singleCellStats.Bud
    outlineStyle = '--';
else
    outlineStyle = '-';
end
handles.cellOutline = plot(axes_handle, [singleCellStats.CellOutlineCoordinates(1:plotResolution:end,2); singleCellStats.CellOutlineCoordinates(1,2)], [singleCellStats.CellOutlineCoordinates(1:plotResolution:end,1); singleCellStats.CellOutlineCoordinates(1,1)],...
    'Color', colors.cellOutline_color, 'ButtonDownFcn', {@deleteObject, 'cell', cellId}, 'Tag', 'cell_outline', 'LineStyle', outlineStyle, 'LineWidth', lineWidth);

% Plot medial axis
try
    handles.medialAxis = plot(axes_handle, [singleCellStats.CellMedialAxisCoordinates(1:plotResolution:end,2); singleCellStats.CellMedialAxisCoordinates(end,2)], ...
        [singleCellStats.CellMedialAxisCoordinates(1:plotResolution:end,1); singleCellStats.CellMedialAxisCoordinates(end,1)], ...
        'Color', colors.medialAxis_color, 'ButtonDownFcn', {@reverseOrientation, cellId}, 'Tag', 'cell_medialAxis', 'LineWidth', lineWidth);
    handles.medialAxisOrientation = plot(axes_handle, singleCellStats.CellMedialAxisCoordinates(1,2), singleCellStats.CellMedialAxisCoordinates(1,1), 'o',...
        'Color', colors.cellPole_color, 'MarkerFaceColor', colors.cellPole_color, 'ButtonDownFcn', {@reverseOrientation, cellId}, 'Tag', 'cell_medialAxis', 'LineWidth', lineWidth, 'MarkerSize', 3);
end

%plot(h_ax, y, x, '.',  'Color', 'green', 'MarkerSize', 1)

% Plot cellID
if isfield(singleCellStats, 'TrackID') && showTrackID && ~singleCellStats.Bud
    label = sprintf(' %d, track: %d', cellId, singleCellStats.TrackID);
else
    label = sprintf(' %d', cellId);
end

handles.label = text(singleCellStats.CellOutlineCoordinates(1,2), singleCellStats.CellOutlineCoordinates(1,1), label,...
    'Color', colors.text_color, 'fontsize', 8, 'ButtonDownFcn', {@deleteObject, 'cell', cellId}, 'parent', axes_handle, 'Tag', 'cell_ID', 'FontSize', fontSize,...
    'Clipping', 'on');

if ~isempty(singleCellStats.Comment)
    try
        if strcmp(singleCellStats.Comment(1:3), '(?)')
            text(singleCellStats.CellOutlineCoordinates(round(end/2),2), singleCellStats.CellOutlineCoordinates(round(end/2),1), '!  ',...
                'Color', [1 0.5 0], 'fontsize', 8, 'ButtonDownFcn', {@showComment, singleCellStats.Comment}, 'parent', axes_handle, 'Tag', 'cell_ID', 'FontSize', fontSize,...
                'Clipping', 'on', 'HorizontalAlignment', 'center', 'fontweight', 'bold');
        end
    end
end



% PLot deleted cell
if singleCellStats.CellDeleted
    fNames = setdiff(fieldnames(handles), {'undoDeleteCell', 'undoDeleteCellData', 'undoDeleteStalkData'});
    
    
    % Add undo-option
    handles.undoDeleteCell = plot([singleCellStats.CellOutlineCoordinates(1:plotResolution:end,2); singleCellStats.CellOutlineCoordinates(end,2)],...
        [singleCellStats.CellOutlineCoordinates(1:plotResolution:end,1); singleCellStats.CellOutlineCoordinates(end,1)],...
        'Color', colors.deletedObject_color, 'LineStyle', '--',...
        'ButtonDownFcn', {@undoDeletion, 'cell', cellId},...
        'parent', axes_handle,...
        'tag', 'cell_undoDeletion',...
        'LineWidth', lineWidth,...
        'UserData', {Stats(cellId), Stats(cellId).ConnectedWith});
    
    % If already stored undo-data is not available -> create it
    if ~isfield(handles, 'undoDeleteCellData')
        handles.undoDeleteCellData = {Stats(cellId), Stats(cellId).ConnectedWith};
    else
        if isempty(handles.undoDeleteCellData)
            handles.undoDeleteCellData = {Stats(cellId), Stats(cellId).ConnectedWith};
        end
    end
    
    if ~isempty(fNames)
        for f = 1:numel(fNames)
            if ~isempty(handles.(fNames{f}))
                handles.(fNames{f}).Visible = 'off';
            end
        end
    end
end

% Plot deleted stalk
if ~isempty(handles.undoDeleteStalkData) && ~singleCellStats.Stalk
    % Plot Connection
    if ~isempty(handles.undoDeleteStalkData{1}.ConnectedWith)
        stalkColor = colors.stalk2_color;
    else
        stalkColor = colors.stalk1_color;
    end
    try
        handles.stalk = plot(axes_handle, [handles.undoDeleteStalkData{1}.StalkCoordinates(1:plotResolution:end,2); handles.undoDeleteStalkData{1}.StalkCoordinates(end, 2)], [handles.undoDeleteStalkData{1}.StalkCoordinates(1:plotResolution:end,1); handles.undoDeleteStalkData{1}.StalkCoordinates(end,1)],...
            'Color', stalkColor, 'ButtonDownFcn', {@deleteObject, 'stalk', cellId}, 'Tag', 'cell_stalk', 'LineWidth', lineWidth, 'Visible', 'off');
        
        handles.undoDeleteStalk = plot(axes_handle, [handles.undoDeleteStalkData{1}.StalkCoordinates(1:plotResolution:end,2); handles.undoDeleteStalkData{1}.StalkCoordinates(end,2)], [handles.undoDeleteStalkData{1}.StalkCoordinates(1:plotResolution:end,1); handles.undoDeleteStalkData{1}.StalkCoordinates(end,1)],...
                    'Color', colors.deletedObject_color, 'LineStyle', '--',...
                    'ButtonDownFcn', {@undoDeletion, 'stalk', cellId},...
                    'tag', 'cell_undoDeletion',...
                    'linewidth', lineWidth,...
                    'UserData', {Stats(cellId), []});
    catch
        sprintf('Stalk of cell #%d could not be plotted.', cellId);
    end
end