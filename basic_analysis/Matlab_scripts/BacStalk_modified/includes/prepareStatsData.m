function stats = prepareStatsData(stats, data)

scale_h = findobj(data.mainFigure, 'Tag', 'Scaling');
scale = str2double(scale_h.String);

% Calculate additional fields
% 'CellStalkLength'
stalkLength = {stats.StalkLength};
noStalks = cellfun(@isempty, stalkLength);
stalkLength(noStalks) = repmat({0}, 1, sum(noStalks));

tempData = cellfun(@(x, y) x+y, {stats.CellLength}, stalkLength, 'UniformOutput', false);
[stats.CellStalkLength] = tempData{:};

% 'CellStalkBudLength'
stalkLength = {stats.StalkLength};
noStalks = cellfun(@isempty, stalkLength);
stalkLength(noStalks) = repmat({0}, 1, sum(noStalks));
budLength = {stats.BudLength};
tempData = cellfun(@(x, y, z) x+y+z, {stats.CellLength}, stalkLength, budLength, 'UniformOutput', false);
[stats.CellStalkBudLength] = tempData{:};

% 'StalkBudLength'
stalkLength = {stats.StalkLength};
noStalks = cellfun(@isempty, stalkLength);
stalkLength(noStalks) = repmat({0}, 1, sum(noStalks));
budLength = {stats.BudLength};
tempData = cellfun(@(x, y) x+y, stalkLength, budLength, 'UniformOutput', false);
tempData = removeZeros(tempData);
[stats.StalkBudLength] = tempData{:};

% 'BudLength'
tempData = {stats.BudLength};
tempData = removeZeros(tempData);
[stats.BudLength] = tempData{:};

% 'BudArea'
tempData = {stats.BudArea};
tempData = removeZeros(tempData);
[stats.BudArea] = tempData{:};

% Scale table
measurementFields = fieldnames(stats);
NCells = numel(stats);
for f = 1:numel(measurementFields)
    % Multiply with scaling
    searchStr = {'a_distance'};
    if sum(cellfun(@(x) ~isempty(x), cellfun(@(x, y) strfind(x, y), {lower(measurementFields{f})}, searchStr, 'UniformOutput', false)))
        tempData = cellfun(@(x, y) x*y, {stats.(measurementFields{f})}, repmat({scale}, 1, NCells), 'UniformOutput', false);
        [stats.(measurementFields{f})] = tempData{:};
    end
    
    searchStr = {'b_distance'};
    if sum(cellfun(@(x) ~isempty(x), cellfun(@(x, y) strfind(x, y), {lower(measurementFields{f})}, searchStr, 'UniformOutput', false)))
        tempData = cellfun(@(x, y) x*y, {stats.(measurementFields{f})}, repmat({scale}, 1, NCells), 'UniformOutput', false);
        [stats.(measurementFields{f})] = tempData{:};
    end
    
    if ~isempty(intersect(measurementFields{f}, {'CellLength', 'CellWidth', 'StalkLength', 'CellStalkLength', 'CellStalkBudLength', 'StalkBudLength', 'BudLength'}))
        tempData = cellfun(@(x, y) x*y, {stats.(measurementFields{f})}, repmat({scale}, 1, NCells), 'UniformOutput', false);
        [stats.(measurementFields{f})] = tempData{:};
    end
    
    if ~isempty(intersect(measurementFields{f}, {'Area', 'BudArea'}))
        tempData = cellfun(@(x, y) x*y, {stats.(measurementFields{f})}, repmat({scale*scale}, 1, NCells), 'UniformOutput', false);
        [stats.(measurementFields{f})] = tempData{:};
    end
end

% Use formula-fields
if isfield(data.settings, 'customMeasurementFieldNames')
    for f = 1:numel(data.settings.customMeasurementFieldNames)
        tempData = cell(numel(stats), 1);
        for i = 1:numel(stats)
            eval(sprintf('tempData{i} = %s;', data.settings.customMeasurementFieldNames(f).formula));
        end
        try
            [stats.(data.settings.customMeasurementFieldNames(f).fieldName)] = tempData{:};
        catch
            tempData = repmat({[]}, numel(stats), 1);
            [stats.(data.settings.customMeasurementFieldNames(f).fieldName)] = tempData{:};
        end
    end
end