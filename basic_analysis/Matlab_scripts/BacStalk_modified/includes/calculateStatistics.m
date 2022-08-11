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

function calculateStatistics(data, ~)

if ishandle(data) || isempty(data)
    h = gcf;
    data = getUIData(h);
end

if ~isfield(data, 'resultsTable')
    return;
end

statData = cell(size(data.resultsTable, 2)-2, 5);

indexes = getDataIndices(data)-1;

for i = 3:size(data.resultsTable, 2)
    try
        column = double(cell2mat(data.resultsTable(indexes+1,i)));
        column(isnan(column)) = [];
        statData{i-2, 1} = mean(column);
        statData{i-2, 2} = std(column);
        statData{i-2, 3} = median(column);
        statData{i-2, 4} = prctile(column, 25);
        statData{i-2, 5} = prctile(column, 75);
    end
end

data.ui.fb(3).g(1).hb(1).cellTable.h.Title = sprintf('Statistics (%d cells)', get(data.tables.tableAnalysis{1}, 'RowCount'));

if ~size(data.resultsTable, 1)
    statData = [];   
end

if ~isempty(statData)
    nonValidEntries = find(cellfun(@numel, statData)>1);
    statData(nonValidEntries) = cell(1, numel(nonValidEntries));
    
    % Remove NaNs
    nonEmptyEntries = find(cellfun(@(x) ~isempty(x), statData));
    nanEntries = find(cellfun(@isnan, statData(nonEmptyEntries)));
    statData(nonEmptyEntries(nanEntries)) = cell(1, numel(nanEntries));
    
    createJavaTable(data.tables.tableStatistics{2}, [], data.tables.tableStatistics{1}, [data.resultsTableHeader(3:end)', statData], {'Measurement', 'Mean', 'Standard deviation', 'Median', '25% Quartile', '75% Quartile'}, [0 0 0 0 0 0], true);

else
    statData = [];
    createJavaTable(data.tables.tableStatistics{2}, [], data.tables.tableStatistics{1}, {}, {'Measurement', 'Mean', 'Standard deviation', 'Median', '25% Quartile', '75% Quartile'}, [0 0 0 0 0 0], true);
end



if isempty(data.resultsTable)
    msgbox('No cells in dataset.', 'Please note', 'warn', 'modal');
    set(findobj(data.mainFigure, 'String', 'Create', 'Style', 'pushbutton'), 'Enable', 'off');
else
    set(findobj(data.mainFigure, 'String', 'Create', 'Style', 'pushbutton'), 'Enable', 'on');
end