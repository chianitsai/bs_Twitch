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

function updateCellsInRoi(src, ~)

data = getUIData(src);

ROI_h = findobj(data.mainFigure, 'Tag', 'ROI_rect');
if isempty(ROI_h)
    msgbox('No ROI defined.', 'No ROI defined', 'help', 'modal');
    return;
end
ROI = ROI_h.Position;


slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
idx = round(slider_h.Value);

if isfield(data.frames, 'cells')
    stats = data.frames(idx).cells.Stats;
    %stats_noBuddingCells = stats(~[stats.Bud]);
    
    coords = [stats.Centroid];
    
    x = coords(1:2:end);
    y = coords(2:2:end);
    
    insideROI = intersect(find(x > ROI(1) & x < (ROI(1) + ROI(3))),...
        find(y > ROI(2) & y < (ROI(2) + ROI(4))));
    
    isBud = [stats.Bud];
    
    deletedCells = true(1, numel(stats));
    
    % Don't label budding cells and cells inside ROI
    deletedCells(isBud) = false;
    deletedCells(insideROI) = false;
    
    % Delete non-budding cells outside roi
    deletedCellsAll = deletedCells | [stats.CellDeleted];
    deletedCellsAll = num2cell(deletedCellsAll);
    
    [stats.CellDeleted] = deletedCellsAll{:};
    
    % Remove budding cells of deleted cells (connected cells)
    deletedCellsIdx = find(deletedCells);
    for i = 1:numel(deletedCellsIdx)
        connectedWith = stats(deletedCellsIdx(i)).ConnectedWith;
        if ~isempty(connectedWith)
            stats(connectedWith).CellDeleted = true;
        end
    end
    data.frames(idx).cells.Stats = stats;
end

setUIData(data.mainFigure, data);
displayImage(src, [], idx)