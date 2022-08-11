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

function [data, tableData, fieldsInclude] = createAnalysisTable(data)
% Cell types to display
showCellType_h = findobj(data.mainFigure, 'Tag', 'popm_showCellType');
showCellType = showCellType_h.Value;

fieldsInclude = data.settings.measurementsFields;

dataAllFrames = assembleData(data);

try
    stats = vertcat(dataAllFrames{:});
catch
    showCellDetectionTab(data.mainFigure, []);
    msgbox('Frame(s) were resegmented after cell tracking was performed and linkages have to be updated. If you click "OK" cell are tracked again.', 'Please note', 'warn', 'modal');
    trackCells(data.mainFigure, []);
    
    data = getUIData(data.mainFigure);
    showAnalysisTab(data.mainFigure, []);
    dataAllFrames = assembleData(data);
    stats = vertcat(dataAllFrames{:});
end

N_allCells = numel(stats);
data.settings.N_allCells = N_allCells;

% Remove all deleted cells
if showCellType < 7
    stats = stats(~[stats.CellDeleted]);
end

DetectStalks_h = findobj(data.mainFigure, 'Tag', 'x___HaveStalks');
DetectStalks = DetectStalks_h.Value;
DetectBuds_h = findobj(data.mainFigure, 'Tag', 'x___FormBuds');
DetectBuds = DetectBuds_h.Value;

if DetectStalks && DetectBuds
    % Filter table
    switch showCellType
        case 1
            % Show all cells: do nothing
        case 2
            % Cells w/o stalks
            stats = stats(~[stats.Bud]);
            stats = stats(~[stats.Stalk]);
        case 3
            % Cells w stalks
            stats = stats(~[stats.Bud]);
            stats = stats([stats.Stalk]);
        case 4
            % Cells w stalks w/o bud cells
            stats = stats(~[stats.Bud]);
            stats = stats([stats.Stalk]);
            stats = stats(cellfun(@isempty, {stats.ConnectedWith}));
        case 5
            % Cells connected to bud cells
            stats = stats(~[stats.Bud]);
            stats = stats([stats.Stalk]);
            stats = stats(~cellfun(@isempty, {stats.ConnectedWith}));
        case 6
            % Bud cells
            stats = stats([stats.Bud]);
        case 7
            % Deleted cells
            stats = stats([stats.CellDeleted]);
        case 8
            % Do nothing
    end
end
if DetectStalks && ~DetectBuds
    % Filter table
    switch showCellType
        case 1
            % Show all cells: do nothing
        case 2
            % Cells w/o stalks
            stats = stats(~[stats.Bud]);
            stats = stats(~[stats.Stalk]);
        case 3
            % Cells w stalks
            stats = stats(~[stats.Bud]);
            stats = stats([stats.Stalk]);
        case 4
            % Deleted cells
            stats = stats([stats.CellDeleted]);
        case 5
            % Do nothing
    end
end
if ~DetectStalks && ~DetectBuds
    switch showCellType
        case 1
            % Show all cells: do nothing
        case 2
            % Deleted cells
            stats = stats([stats.CellDeleted]);
        case 3
            % Do nothing
    end
end

if ~isempty(stats)
    %% Assemble and scale data
    stats = prepareStatsData(stats, data);
    
    % Filter data
    filterCells_h = findobj(data.mainFigure, 'Tag', 'cb_filterCells');
    filterValue_h = findobj(data.mainFigure, 'Tag', 'popm_filterValue');
    value = str2double(filterValue_h.String);
    filterValue_h.String = num2str(value);
    if isempty(filterValue_h.String) || numel(value) > 1
        filterValue_h.String = '1';
        value = 1;
    end
    
    if filterCells_h.Value && ~isempty(stats)
        filterField_h = findobj(data.mainFigure, 'Tag', 'popm_filterCellField');
        filterOperator_h = findobj(data.mainFigure, 'Tag', 'popm_filterOperator');
        
        filterField = filterField_h.String{filterField_h.Value};
        operator = filterOperator_h.String{filterOperator_h.Value};
        
        valid = false(numel(stats), 1);
        for i = 1:numel(stats)
            if ~isempty(stats(i).(filterField))
                eval(sprintf('valid(i) = stats(i).%s %s %f;', filterField, operator, value));
            end
        end
        %eval(sprintf('idx = find([stats.%s] %s %f);', filterField, operator, value));
        stats = stats(valid);
    end
    
    % Fill table
    tableData = cell(numel(stats), numel(fieldsInclude));
    for f = 1:numel(fieldsInclude)
        if isfield(stats, fieldsInclude{f})
            
            tempData = {stats.(fieldsInclude{f})};
            
            cellType = cellfun(@(x) iscell(x), tempData);
            if sum(cellType)
                tempData(cellType) = cellfun(@(x) [x{:}], tempData(cellType), 'UniformOutput', false);
            end
            
            tableData(:,f) = tempData';
        else
            % If field is not present fill with NaNs
            tableData(:,f) = cell(numel(stats), 1);
        end
    end
    
else
    tableData = [];
end


% Display table
data.ui.fb(3).g(1).vb(1).cellList.h.Title = sprintf('Cell list (%d of %d cells)', size(tableData, 1), N_allCells);
data.resultsTable = tableData;
data.resultsTableHeader = fieldsInclude;
isEditable = false(1, numel(fieldsInclude));
commentColumn = find(strcmp(fieldsInclude, 'Comment'));
if ~isempty(commentColumn)
    isEditable(commentColumn) = true;
end
createJavaTable(data.tables.tableAnalysis{2}, [], data.tables.tableAnalysis{1}, [num2cell((1:size(tableData, 1))'), tableData], [{'Index'}, fieldsInclude], [false, isEditable]);
calculateStatistics(data)

function dataAllFrames = assembleData(data)

% Assemble frameIDs
nonEmptyCells = find(cellfun(@(x) ~isempty(x), {data.frames.cells}));
dataAllFrames = cellfun(@(x, y) {x.Stats, y}, {data.frames(nonEmptyCells).cells}, num2cell(nonEmptyCells), 'UniformOutput', false);

for i = 1:numel(dataAllFrames)
    % Add frame
    frames = repmat({dataAllFrames{i}{1,2}}, numel(dataAllFrames{i}{1,1}), 1);
    [dataAllFrames{i}{1,1}.Frame] = frames{:};
    
    % Add filenames
    for ch = 1:numel(data.settings.channelNames)
        [~, filename, ext] = fileparts(data.frames(i).(data.settings.channelNames{ch}));
        filenames = repmat({[filename, ext]}, 1, numel(frames));
        [dataAllFrames{i}{1,1}.(sprintf('Filename_%s', data.settings.channelNames{ch}))] = filenames{:};
    end
end

dataAllFrames = cellfun(@(x) x{1}, dataAllFrames, 'UniformOutput', false);

if sum(cellfun(@isempty, dataAllFrames)) == numel(dataAllFrames)
    msgbox('All frames are empty!', 'Please note', 'error', 'modal');
    return;
end

% Calculate additional data
for i = 1:numel(dataAllFrames)
    budLength = repmat({0}, 1, numel(dataAllFrames{i}));
    budArea = repmat({0}, 1, numel(dataAllFrames{i}));
    connections = {dataAllFrames{i}.ConnectedWith};
    
    hasConnection = cellfun(@(x) ~isempty(x), connections);
    isBud = [dataAllFrames{i}.Bud];
    
    validCells = hasConnection & ~isBud;
    connections(~validCells) = [];
    connections = [connections{:}];
    
    if ~isempty(connections)
        budLength(validCells) = {dataAllFrames{i}(connections).CellLength};
        budArea(validCells) = {dataAllFrames{i}(connections).Area};
    end
    
    [dataAllFrames{i}.BudLength] = budLength{:};
    [dataAllFrames{i}.BudArea] = budArea{:};
    
end
%end