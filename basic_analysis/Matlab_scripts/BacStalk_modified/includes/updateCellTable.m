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

function updateCellTable(data, cells)

if ~isempty(cells)
    if ~isempty(cells.Stats)
        cellTable = [{cells.Stats.CellID}',...
            {cells.Stats.Area}', ...
            {cells.Stats.Stalk}', ...
            {cells.Stats.CellDeleted}'];
        
        createJavaTable(data.tables.tableCells{2}, [], data.tables.tableCells{1}, cellTable, {'CellID', 'Area (px)', 'Stalk', 'Deleted'}, [false, false, false, true], true);
        
    else
        createJavaTable(data.tables.tableCells{2}, [], data.tables.tableCells{1}, {}, {'No cells found.'}, false, true);
    end
    
else
    createJavaTable(data.tables.tableCells{2}, [], data.tables.tableCells{1}, {}, {'Cell were not segmented.'}, false, true);
end