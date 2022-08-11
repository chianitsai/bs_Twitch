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

% Undo deletion of cell/stalk
function undoDeletion(src, eventdata, objectType, objectId)
data = getUIData(src);
slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
fig_handle = data.mainFigure;

cells = data.frames(round(slider_h.Value)).cells;

if isempty(eventdata)
    eventdata.Button = 1;
end

switch eventdata.Button
    case 1
        stalk2_color = findobj(data.mainFigure, 'tag', 'StalkColor2');
        colors.stalk2_color = stalk2_color.UserData;
        
        handles = cells.Handles;
        
        
        fNames = setdiff(fieldnames(handles(objectId)), {'undoDeleteCellData', 'undoDeleteStalkData'});
        for f = 1:numel(fNames)
            if ~isempty(handles(objectId).(fNames{f}))
                if ~isempty(strfind(fNames{f}, 'undo'))
                    handles(objectId).(fNames{f}).Visible = 'Off';
                else
                    handles(objectId).(fNames{f}).Visible = 'On';
                end
            end
        end
        
        if ~isempty(handles(objectId).undoDeleteCell)
            if ~isempty(cells.Stats(objectId).Comment)
                % fprintf('Cell #%d, reason for it''s deletion: %s\n', objectId, cells.Stats(objectId).Comment);
                %t_h = text(cells.Stats(objectId).CellOutlineCoordinates(round(end/2),2), cells.Stats(objectId).CellOutlineCoordinates(round(end/2),1),...
                %sprintf('This cell was deleted because:\n%s\n(Click to close)', cells.Stats(objectId).Comment), 'Parent', data.axes.main, 'BackgroundColor', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @deleteComment);
                
                
                if strcmp(cells.Stats(objectId).Comment(1:3), '(?)')
                    warningStr = 'Segmentation might be wrong';
                else
                    warningStr = 'Automatically marked as deleted';
                end
                
                t_h = text(cells.Stats(objectId).CellOutlineCoordinates(round(end/2),2), cells.Stats(objectId).CellOutlineCoordinates(round(end/2),1),...
                    warningStr, 'Parent', data.axes.main, 'BackgroundColor', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @deleteComment);
                
                t = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.8, 'TimerFcn', {@deleteComment, t_h}, 'Tag', 'timer_comment');
                start(t)
            else
                % fprintf('Cell #%d, Reason for deletion: Deleted by user\n', objectId);
                
                %t_h = text(cells.Stats(objectId).CellOutlineCoordinates(round(end/2),2), cells.Stats(objectId).CellOutlineCoordinates(round(end/2),1),...
                %'This cell was deleted because:\nDeleted b user.\n(Click to close)', 'Parent', data.axes.main, 'BackgroundColor', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @deleteComment);
                
                
            end

            undoData = handles(objectId).undoDeleteCellData;
            
            
            if numel(fieldnames(cells.Stats(objectId))) == numel(fieldnames(undoData{1}))
                cells.Stats(objectId) = undoData{1};
            else % This part is required because after tracking the undo-data does not contain the trackID
                fNames_undoData = fieldnames(undoData{1});
                for f = 1:numel(fNames_undoData)
                    cells.Stats(objectId).(fNames_undoData{f}) = undoData{1}.(fNames_undoData{f});
                end
            end
            
            if cells.Stats(objectId).Bud
                try
                    % Check if stalk of other cell still exists
                    if ~cells.Stats(undoData{2}).CellDeleted && cells.Stats(undoData{2}).Stalk
                        cells.Stats(undoData{2}).ConnectedWith = objectId;
                        cells.Stats(objectId).ConnectedWith = undoData{2};
                        handles(undoData{2}).stalk.Color = colors.stalk2_color;
                    else
                        handles(objectId).cellOutline.LineStyle = '-';
                        cells.Stats(objectId).Bud = false;
                    end
                end
            else
                if ~isempty(undoData{2}) % Undo Bud
                    cells.Stats(objectId).ConnectedWith = undoData{2};
                    handles(objectId).stalk.Color = colors.stalk2_color;
                    
                    cells.Stats(undoData{2}).Bud = true;
                    handles(undoData{2}).cellOutline.LineStyle = '--';
                    cells.Stats(undoData{2}).CellDeleted = false;
                    handles(undoData{2}).cellOutline.Visible = 'on';
                    handles(undoData{2}).label.Visible = 'on';
                    handles(undoData{2}).medialAxis.Visible = 'on';
                    handles(undoData{2}).medialAxisOrientation.Visible = 'on';
                    handles(undoData{2}).undoDeleteCell.Visible = 'off';
                    
                    
                    showNote(data.axes.main, [cells.Stats(objectId).StalkCoordinates(end,2), cells.Stats(objectId).StalkCoordinates(end,1)], 'Bud assigned', 'orange')

                end
            end
            handles(objectId).undoDeleteCell = [];
        end
        
        if ~isempty(handles(objectId).undoDeleteStalk)
            undoData = handles(objectId).undoDeleteStalkData;
            cells.Stats(objectId) = undoData{1};
            
            if ~isempty(undoData{2}) % Undo Bud
                cells.Stats(objectId).ConnectedWith = undoData{2};
                cells.Stats(undoData{2}).ConnectedWith = objectId;
                
                cells.Stats(objectId).Stalk = true;
                handles(objectId).stalk.Color = colors.stalk2_color;
                cells.Stats(undoData{2}).Bud = true;
                handles(undoData{2}).cellOutline.LineStyle = '--';
                
                handles(undoData{2}).cellOutline.Visible = 'on';
                handles(undoData{2}).label.Visible = 'on';
                handles(undoData{2}).medialAxis.Visible = 'on';
                handles(undoData{2}).medialAxisOrientation.Visible = 'on';
                handles(undoData{2}).undoDeleteCell.Visible = 'off';
                showNote(data.axes.main, [cells.Stats(objectId).StalkCoordinates(end,2), cells.Stats(objectId).StalkCoordinates(end,1)], 'Bud assigned', 'orange')
            end
            
            handles(objectId).undoDeleteCell = [];
        end
        
        cells.Stats(objectId).CellDeleted = false;
        
        
        data.frames(round(slider_h.Value)).cells = cells;
        
        %updateCellTable(data, cells)
        idx = data.tables.tableCells{1}.getModel.getIndexes+1;
        row = find(idx == objectId)-1;
        switch objectType
            case 'stalk'
                data.tables.tableCells{1}.setValueAt(true, row, 2);
            case 'cell'
                data.tables.tableCells{1}.setValueAt(false, row, 3);
        end
        setUIData(data.mainFigure, data);
        
    case 3
       showDeletionComment(data.axes.main, cells.Stats(objectId))
end
