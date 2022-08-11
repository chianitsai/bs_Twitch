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

function clickCellTable(src, eventdata, cellIDs)
data = getUIData(src);

zoom(data.axes.main, 'off')
pan(data.axes.main, 'off')
datacursormode(data.mainFigure, 'off')

try
    % Delete the draggable ROI
    delete(data.ui.ROI_rect);
end

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');

if nargin < 3
    
    indices = src.getSelectedRows;
    
    
    cellIDs = zeros(numel(indices), 1);
    for i = 1:numel(indices)
        try
            cellIDs(i) = src.getValueAt(indices(i), 0);
        catch
            cellIDs(i) = str2double(src.getValueAt(indices(i), 0));
        end
    end
    
    if ~src.getModel.isFiltersApplied && src.SelectedColumn == 3
        if src.SelectedColumn == 3 && numel(indices) == 1
            if src.getValueAt(indices, 3)
                src.setValueAt(false, indices, 3);
                undoDeletion(data.frames(round(slider_h.Value)).cells.Handles(cellIDs).cellOutline, [], 'cell', cellIDs)
            else
                src.setValueAt(true, indices, 3);
                deleteObject(data.frames(round(slider_h.Value)).cells.Handles(cellIDs).cellOutline, [], 'cell', cellIDs)
            end
        end
    else
        if src.SelectedColumn == 3
            msgbox('The table can only be modified if it is not sorted and not filtered. Please reload the image by clicking on the slider to modify the deleted state of a cell.', 'Please note', 'help', 'modal');
        end
    end
end


singleCellStats = data.frames(round(slider_h.Value)).cells.Stats(cellIDs);

coords = [singleCellStats.Centroid];
x = coords(1:2:end);
y = coords(2:2:end);

CellSize_h = findobj(data.mainFigure, 'Tag', 'CellSize');
CellSize = 5*str2num(CellSize_h.String);

xLimits = [min(x) - CellSize, max(x) + CellSize];
yLimits = [min(y) - CellSize, max(y) + CellSize];

data.axes.main.XLim = xLimits;
data.axes.main.YLim = yLimits;
