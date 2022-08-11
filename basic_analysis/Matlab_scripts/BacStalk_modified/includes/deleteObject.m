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

function deleteObject(src, eventdata, objectType, objectId)
data = getUIData(src);

if isempty(eventdata)
    eventdata.Button = 1;
end

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
fig_handle = data.mainFigure;

cells = data.frames(round(slider_h.Value)).cells;

switch eventdata.Button
    case 1 % Only delete stalk
        
        deletedObject_color_h = findobj(data.mainFigure, 'tag', 'DeletedObjectColor');
        inactiveColor = deletedObject_color_h.UserData;
        
        lineWidth_h = findobj(data.mainFigure, 'tag', 'LineWidth');
        lineWidth = str2double(lineWidth_h.String);
        showTrackID_h = findobj(data.mainFigure, 'tag', 'ShowTrackID');
        showTrackID = showTrackID_h.Value;
        stalk1_color = findobj(data.mainFigure, 'tag', 'StalkColor1');
        colors.stalk1_color = stalk1_color.UserData;
        
        plotResolution_h = findobj(data.mainFigure, 'tag', 'PlotResolution');
        plotResolution = str2double(plotResolution_h.String);
        
        handles = cells.Handles;
        
        switch objectType
            case 'cell'
                % Delete cell+stalk
                fNames = setdiff(fieldnames(handles(objectId)), {'undoDeleteCell', 'undoDeleteCellData', 'undoDeleteStalkData'});
                
                % Add undo-option
                cellCoords = cells.Stats(objectId).CellOutlineCoordinates;
                
                if cells.Stats(objectId).Stalk
                    stalkCoords = cells.Stats(objectId).StalkCoordinates;
                    
                    if ~isempty(cells.Stats(objectId).ConnectedWith)
                        otherCell = cells.Stats(objectId).ConnectedWith;
                        cells.Stats(otherCell).Bud = false;
                        handles(otherCell).cellOutline.LineStyle = '-';
                        cells.Stats(objectId).ConnectedWith = [];
                        cells.Stats(otherCell).ConnectedWith = [];
                    else
                        otherCell = [];
                    end
                    
                    
                    %cells.Stats(objectId).StalkLength = [];
                else
                    otherCell = [];
                end
                
                try
                    if cells.Stats(objectId).Bud
                        motherCell = find(cellfun(@(x) ~isempty(x), cellfun(@(x, y) find(x==y), {cells.Stats.ConnectedWith}, repmat({objectId}, 1, numel(cells.Stats)), 'UniformOutput', false)));
                        handles(motherCell).stalk.Color = colors.stalk1_color;
                        cells.Stats(motherCell).ConnectedWith = [];
                        cells.Stats(objectId).ConnectedWith = [];
                        otherCell = motherCell;
                    end
                end
                
                
                handles(objectId).undoDeleteCell = plot([cellCoords(1:plotResolution:end,2); cellCoords(end,2)], [cellCoords(1:plotResolution:end,1); cellCoords(end,1)],...
                    'Color', inactiveColor, 'LineStyle', '--',...
                    'ButtonDownFcn', {@undoDeletion, 'cell', objectId},...
                    'parent', data.axes.main,...
                    'tag', 'cell_undoDeletion',...
                    'linewidth', lineWidth,...
                    'UserData', {cells.Stats(objectId), otherCell});
                
                handles(objectId).undoDeleteCellData = {cells.Stats(objectId), otherCell};
                
                cells.Stats(objectId).CellDeleted = true;
                
            case 'stalk'
                
                fNames = {'stalk'};
                % Add undo-option
                stalkCoords = cells.Stats(objectId).StalkCoordinates;
                
                if ~isempty(cells.Stats(objectId).ConnectedWith)
                    otherCell = cells.Stats(objectId).ConnectedWith;
                    cells.Stats(otherCell).Bud = false;
                    handles(otherCell).cellOutline.LineStyle = '-';
                    cells.Stats(objectId).ConnectedWith = [];
                    cells.Stats(otherCell).ConnectedWith = [];
                else
                    otherCell = [];
                end
                
                handles(objectId).undoDeleteStalk = plot([stalkCoords(1:plotResolution:end,2); stalkCoords(end,2)], [stalkCoords(1:plotResolution:end,1); stalkCoords(end,1)],...
                    'Color', inactiveColor, 'LineStyle', '--',...
                    'ButtonDownFcn', {@undoDeletion, 'stalk', objectId},...
                    'parent', data.axes.main,...
                    'tag', 'cell_undoDeletion',...
                    'linewidth', lineWidth,...
                    'UserData', {cells.Stats(objectId), otherCell});
                
                handles(objectId).undoDeleteStalkData = {cells.Stats(objectId), otherCell};
                
                cells.Stats(objectId).Stalk = false;
                cells.Stats(objectId).StalkLength = [];
                
                
        end
        if ~isempty(fNames)
            for f = 1:numel(fNames)
                if ~isempty(handles(objectId).(fNames{f}))
                    handles(objectId).(fNames{f}).Visible = 'off';
                end
            end
        end
        
        cells.Handles = handles;
        data.frames(round(slider_h.Value)).cells = cells;
        %updateCellTable(data, cells)
        idx = data.tables.tableCells{1}.getModel.getIndexes+1;
        row = find(idx == objectId)-1;
        switch objectType
            case 'stalk'
                data.tables.tableCells{1}.setValueAt(false, row, 2);
            case 'cell'
                data.tables.tableCells{1}.setValueAt(true, row, 3);
        end
        
        setUIData(data.mainFigure, data);
        
    case 3
        showDeletionComment(data.axes.main, cells.Stats(objectId))
end