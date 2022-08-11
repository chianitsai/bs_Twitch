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

function [compiledData, unit] = compileDataSimple(src, ~, frames, cellIDs, fields)

data = getUIData(src);

scaling_h = findobj(data.mainFigure, 'Tag', 'Scaling');
scaling = str2double(scaling_h.String);

compiledData = nan(numel(frames),numel(fields));

% Assemble frameIDs
nonEmptyCells = find(cellfun(@(x) ~isempty(x), {data.frames.cells}));
stats = cellfun(@(x, y) {x.Stats, y}, {data.frames(nonEmptyCells).cells}, num2cell(nonEmptyCells), 'UniformOutput', false);

for i = 1:numel(stats)
    frameIDs = repmat({stats{i}{1,2}}, numel(stats{i}{1,1}), 1);
    [stats{i}{1,1}.Frame] = frameIDs{:};
end

stats = cellfun(@(x) x{1}, stats, 'UniformOutput', false);

% Calculate additional data
for i = 1:numel(stats)
    budLength = repmat({0}, 1, numel(stats{i}));
    budArea = repmat({0}, 1, numel(stats{i}));
    connections = {stats{i}.ConnectedWith};
    
    hasConnection = cellfun(@(x) ~isempty(x), connections);
    isBud = [stats{i}.Bud];
    
    validCells = hasConnection & ~isBud;
    connections(~validCells) = [];
    connections = [connections{:}];
    
    if ~isempty(connections)
        budLength(validCells) = {stats{i}(connections).CellLength};
        budArea(validCells) = {stats{i}(connections).Area};
    end
    
    [stats{i}.BudLength] = budLength{:};
    [stats{i}.BudArea] = budArea{:};
end


stats = vertcat(stats{:});
cellIDsAll = [stats.CellID]';
frameIDs = [stats.Frame]';

% Compile data
datapoints = zeros(numel(frames), 1);
for f = 1:numel(frames)
    datapoints(f) = intersect(find(cellIDsAll == cellIDs(f)), find(frameIDs == frames(f)));
end
stats = stats(datapoints);

stats = prepareStatsData(stats, data);

warning_subset = false;
warning_fields = [];

for m = 1:numel(fields)
    data_temp = nan(numel(stats), 1);
    for i = 1:numel(stats)
        if ~isempty(stats(i).(fields{m}))
            data_temp(i) = stats(i).(fields{m});
        end
    end
    
    if numel([stats.(fields{m})]) ~= numel(data_temp)
        warning_subset = true;
        if isempty(warning_fields)
            warning_fields = fields{m};
        else
            warning_fields = [warning_fields, ' & ', fields{m}];
        end
    end
    %data_temp = [stats.(fields{m})];
    
    unit{m} = ' (a.u.)';
    
    % search for volumes
    searchStr = {'area', 'budarea'};
    if sum(cellfun(@(x) ~isempty(x), cellfun(@(x, y) strfind(x, y), repmat({lower(fields{m})}, 1, numel(searchStr)), searchStr, 'UniformOutput', false)))
        unit{m} = ' (\mum^2)';
    end
    
    % search for lengths
    searchStr = {'length', 'cellwidth', 'distance'};
    
    if sum(cellfun(@(x) ~isempty(x), cellfun(@(x, y) strfind(x, y), repmat({lower(fields{m})}, 1, numel(searchStr)), searchStr, 'UniformOutput', false)))
        unit{m} = ' (\mum)';
    end
    
    if ~isempty(data_temp)
        compiledData(:, m) = data_temp;
    end
    
end

if warning_subset
    uiwait(msgbox(sprintf('The selected field(s) "%s" does/do not contain data for all cells. Please note that empty measurements will not be shown!', warning_fields), 'Warning', 'help', 'modal'))
end