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

function exportCSV(src, ~)

data = getUIData(src);

% Load previous directory
if isdeployed
    if exist('directory.mat','file')
        load('directory.mat');
    else
        directory = '';
    end
else
    if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
        load('directory.mat');
    else
        directory = data.guiPath;
    end
end

[filename, directory] = uiputfile({'*.csv'}, 'Export data to csv-file', fullfile(directory, 'exportedData.csv'));

if directory
    toggleBusyPointer(data, 1)
    
    indexes = getDataIndices(data);
    
    tableData = data.resultsTable(indexes, :);
    
    tableData = cell2table(tableData, 'VariableNames', data.resultsTableHeader);

    writetable(tableData, fullfile(directory, filename),'Delimiter',',')  
    
    toggleBusyPointer(data, 0)
end