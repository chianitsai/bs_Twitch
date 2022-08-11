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

function data = filterCells(src, ~, tableData, columnNames)

data = getUIData(src);

filterCells_h = findobj(data.mainFigure, 'Tag', 'cb_filterCells');

filterValue_h = findobj(data.mainFigure, 'Tag', 'popm_filterValue');
value = str2double(filterValue_h.String);
filterValue_h.String = num2str(value);
if isempty(filterValue_h.String) || numel(value) > 1
    filterValue_h.String = '1';
    value = 1;
end

if filterCells_h.Value && ~isempty(tableData)
    filterField_h = findobj(data.mainFigure, 'Tag', 'popm_filterCellField');
    filterOperator_h = findobj(data.mainFigure, 'Tag', 'popm_filterOperator');
    
    column = find(strcmp(filterField_h.String{filterField_h.Value}, columnNames));
    operator = filterOperator_h.String{filterOperator_h.Value};
    
    eval(sprintf('idx = find(cell2mat(tableData(:,column)) %s %f);', operator, value));
    tableData = tableData(idx, :);
end

%data.tableAnalysis.Data = tableData;
data.ui.fb(3).g(1).vb(1).cellList.h.Title = sprintf('Cell list (%d of %d cells)', size(tableData, 1), data.settings.N_allCells);
data.resultsTable = tableData;
data.resultsTableHeader = columnNames;

setUIData(data.mainFigure, data);

drawnow;

isEditable = false(1, numel(columnNames));
commentColumn = find(strcmp(columnNames, 'Comment'));
if ~isempty(commentColumn)
    isEditable(commentColumn) = true;
end

createJavaTable([], [], data.tableAnalysis, [num2cell((1:size(tableData, 1))'), tableData], [{'Index'}, columnNames], [false, isEditable]);
set(handle(data.tableAnalysis.getModel, 'CallbackProperties'), 'IndexChangedCallback', @calculateStatistics)

calculateStatistics(data);

