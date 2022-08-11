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

function showCellsAnalysisTable(src, ~)
data = getUIData(src);
if ~isempty(data.resultsTable)
    selectedCell = data.tables.tableAnalysis{1}.getSelectedRows;
        
    if numel(selectedCell) > 1 || isempty(selectedCell)
        msgbox('Please select only one single cell.', 'Please note', 'help', 'modal');
        return;
    end
       
    cellID = data.tables.tableAnalysis{1}.getModel.getValueAt(selectedCell,2);
    frame = data.tables.tableAnalysis{1}.getModel.getValueAt(selectedCell,1);
    
    displayImage(src, [], frame);
    
    clickCellTable(data.tables.tableCells, [], cellID);
    showCellDetectionTab(src, []);
    
else
    msgbox('Please select a cell fist.', 'Please note', 'help', 'modal');
end