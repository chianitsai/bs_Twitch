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

function [img_map, offset, compiledData, ticks, sortIdx] = compileData(src, ~, frames, cellIDs, fields, fullCell, alignment, sortMode, channel, orientateCells, backgroundSubtraction, intensityNormalization)

data = getUIData(src);
scaling_h = findobj(data.mainFigure, 'Tag', 'Scaling');
scaling = str2double(scaling_h.String);

compiledData = cell(numel(frames), 3);


if fullCell
    % Load images
    framesToLoad = unique(frames);
    img = cell(max(framesToLoad), 1);
    for i = 1:numel(framesToLoad)
        idx = framesToLoad(i);
        img{idx} = double(imread(data.frames(idx).(channel)));
        
        if size(img{idx}, 3) > 1
            img{idx} = sum(img{idx}, 3);
        end
        
        if ~isempty(data.frames(1).tform)
            img{idx} = imwarp(img{idx}, data.frames(idx).tform, 'OutputView', imref2d(size(img{idx})), 'Interp', 'linear', 'FillValues', mean(img{idx}(:)));
        end
    end
end

% Collect data
nonEmptyCells = find(cellfun(@(x) ~isempty(x), {data.frames.cells}));
stats = cellfun(@(x, y) {x.Stats, y}, {data.frames(nonEmptyCells).cells}, num2cell(nonEmptyCells), 'UniformOutput', false);

for i = 1:numel(stats)
    frameIDs = repmat({stats{i}{1,2}}, numel(stats{i}{1,1}), 1);
    [stats{i}{1,1}.Frame] = frameIDs{:};
end

stats = cellfun(@(x) x{1}, stats, 'UniformOutput', false);

stats = vertcat(stats{:});

cellIDsAll = [stats.CellID]';
frameIDs = [stats.Frame]';

budArea = zeros(numel(frames), 1);
cells = {data.frames.cells};
imageSizes = cell(1, numel(cells));
for f = 1:numel(cells)
    if ~isempty(cells{f})
        imageSizes{f} = cells{f}.ImageSize;
    end
end

%imageSizes = cellfun(@(x) [x.ImageSize], {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells}, 'UniformOutput', false);

% Compile data
for f = 1:numel(frames)
    dataPoint = intersect(find(cellIDsAll == cellIDs(f)), find(frameIDs == frames(f)));
    
    % Get Medial Axis Fluorescence
    if fullCell
        compiledData{f, 1} = getCellRibbon(stats(dataPoint), imageSizes{frames(f)}, scaling);
    else
        compiledData{f, 1} = stats(dataPoint).(fields{1});
    end
    
    
    % If cell has stalk get other values
    if stats(dataPoint).Stalk
        if fullCell
            compiledData{f, 2} = num2cell(stats(dataPoint).StalkIdx');
        else
            compiledData{f, 2} = stats(dataPoint).(fields{2});
        end
        % Resize it
        % Future: scale the stalk length correctly
        
        % If cell has budding cell get its data
        if ~isempty(stats(dataPoint).ConnectedWith)
            buddingCell = intersect(find(cellIDsAll == stats(dataPoint).ConnectedWith), find(frameIDs == frames(f)));
            
            if fullCell
                compiledData{f, 3} = getCellRibbon(stats(buddingCell), imageSizes{frames(f)}, scaling);
            else
                compiledData{f, 3} = ...
                    stats(buddingCell).(fields{1});
            end
        end
    end
    
    if fullCell
        for i = 1:size(compiledData, 2)
            for j = 1:numel(compiledData{f, i})
                compiledData{f, i}{j} = img{frames(f)}(compiledData{f, i}{j});
            end
        end
    end
    
    % Display intensity maxima in the first half (orientateCells==2) or second half (orientateCells=>=3)
    if ~stats(dataPoint).Stalk && orientateCells > 1
        if iscell(compiledData{f, 1})
            lineProfile = cellfun(@max, compiledData{f, 1});
        else
            lineProfile = compiledData{f, 1};
        end
        
        [~, maxIdx] = max(lineProfile);
        if (orientateCells == 2 && maxIdx > numel(lineProfile)/2) ||...
                (orientateCells == 3 && maxIdx < numel(lineProfile)/2)
            compiledData{f, 1} = flip(compiledData{f, 1});
        end
    end
    
    if strcmp(sortMode, 'Bud area')
        if ~isempty(stats(dataPoint).ConnectedWith)
            budArea(f) = stats(buddingCell).Area;
        else
            budArea(f) = 0;
        end
    end
    
end

% Subtract background from data (if intensity normalization is distabled)
if backgroundSubtraction && ~intensityNormalization
    if fullCell
        nonEmptyEntries = cellfun(@(x) ~isempty(x), compiledData);
        minValue = cellfun(@(x) cellfun(@(x) min(double(x)), x), compiledData(nonEmptyEntries), 'UniformOutput', false);
        minValue = min([minValue{:}]);
        
        for i = 1:size(compiledData, 1)           
            for d = 1:3
                if ~isempty(compiledData{i,d})
                    compiledData{i,d} = cellfun(@(x, minV) double(x)-minV, compiledData{i,d}, repmat({minValue}, 1, numel(compiledData{i,d})), 'UniformOutput', false);
                end
            end
        end
    else
        minValue = cellfun(@(x) min(x), compiledData(:), 'UniformOutput', false);
        minValue = min([minValue{:}]);
        
        for i = 1:size(compiledData, 1)
            compiledData(i,:) = cellfun(@(x, minV) x-minV, compiledData(i,:), repmat({minValue}, 1, 3), 'UniformOutput', false);
        end
    end
end

% Do intensity normalization
if intensityNormalization
    if fullCell
        nonEmptyEntries = cellfun(@(x) ~isempty(x), compiledData);
        minValue = cellfun(@(x) cellfun(@(x) min(double(x)), x), compiledData(nonEmptyEntries), 'UniformOutput', false);
        
        if backgroundSubtraction
            minValue = min([minValue{:}]);
        else
            minValue = 0;
        end
        
        for i = 1:size(compiledData, 1)
            maxVal = zeros(1, 3);
            for d = 1:3
                if ~isempty(compiledData{i, d})
                    maxVal(d) = max(cellfun(@(x) max(double(x)), compiledData{i, d}));
                else
                    maxVal(d) = 0;
                end
            end
            maxValuePerCell = max(maxVal);
            
            for d = 1:3
                if ~isempty(compiledData{i,d})
                    compiledData{i,d} = cellfun(@(x, minV, maxV) (double(x)-minV)./(maxV-minV), compiledData{i,d}, repmat({minValue}, 1, numel(compiledData{i,d})), repmat({maxValuePerCell}, 1, numel(compiledData{i,d})), 'UniformOutput', false);
                end
            end
        end
    else
        minValue = cellfun(@(x) min(x), compiledData(:), 'UniformOutput', false);
        
        if backgroundSubtraction
            minValue = min([minValue{:}]);
        else
            minValue = 0;
        end
        
        for i = 1:size(compiledData, 1)
            maxValuePerCell = max([compiledData{i,:}]);
            compiledData(i,:) = cellfun(@(x, minV, maxV) (x-minV)/(maxV-minV), compiledData(i,:), repmat({minValue}, 1, 3), repmat({maxValuePerCell}, 1, 3), 'UniformOutput', false);
        end
    end
end

sizes = cellfun(@numel, compiledData);

% Sort cells
if ~isempty(sortMode)
    switch sortMode
        case 'Cell length'
            sizesSort = sizes(:,1);
            
        case 'Mother cell length'
            sizesSort = sizes(:,1);
            
        case 'Stalk length'
            sizesSort = sizes(:,2);
            
        case 'Cell+stalk length'
            sizesSort = sum(sizes(:,[1 2]), 2);
            
        case 'Mother cell+stalk length'
            sizesSort = sum(sizes(:,[1 2]), 2);
            
        case 'Bud area'
            sizesSort = budArea;
            
        case 'Bud length'
            sizesSort = sizes(:,3);
            
        case 'Mother cell+bud length'
            sizesSort = sum(sizes(:,[1 3]), 2);
            
        case 'Mother cell+stalk+bud length'
            sizesSort = sum(sizes, 2);
            
        otherwise % Sort as the appear in table
            sizesSort = 1:size(sizes, 1);
    end
    [~, sortIdx] = sort(sizesSort, 'descend');
    sizes = sizes(sortIdx, :);
    compiledData = compiledData(sortIdx,:);
end

sX = max(sum(sizes, 2))+2;

if fullCell
    sizesY = zeros(size(compiledData));
    for i = 1:numel(compiledData)
        if ~isempty(compiledData{i})
            sizesY(i) = max(cellfun(@numel, compiledData{i}));
        end
    end
    sY = max(sum(sizesY, 1));
else
    sY = size(compiledData, 1);
end

offset_individual = zeros(sY, 1);

% Align cells
switch alignment
    case 1 % Cell pole
        offset = 1;
        
    case 2 % Cell center
        offset = max(ceil(sizes(:,1)/2))+1;
        for y = 1:size(compiledData, 1)
            offset_individual(y) = ceil(numel(compiledData{y,1})/2);
        end
        
    case 3 % Cell-stalk
        offset = max(sizes(:,1))+1;
        for y = 1:size(compiledData, 1)
            offset_individual(y) = numel(compiledData{y,1});
        end
        
    case 4 % Stalk center
        offset = max(ceil(sizes(:,1)+sizes(:,2)/2))+1;
        for y = 1:size(compiledData, 1)
            offset_individual(y) = ceil(numel(compiledData{y,1})+numel(compiledData{y,2})/2);
        end
        
    case 5 % Stalk-budding cell
        offset = max(sizes(:,1)+sizes(:,2))+1;
        for y = 1:size(compiledData, 1)
            offset_individual(y) = numel(compiledData{y,1})+numel(compiledData{y,2});
        end
        
    case 6 % Budding cell center
        offset = max(ceil(sizes(:,1)+sizes(:,2)+sizes(:,3)/2))+1;
        for y = 1:size(compiledData, 1)
            offset_individual(y) = ceil(numel(compiledData{y,1})+numel(compiledData{y,2})+numel(compiledData{y,3})/2);
        end
        
    case 7 % Budding cell pole
        offset = max(sizes(:,1)+sizes(:,2)+sizes(:,3))+1;
        for y = 1:size(compiledData, 1)
            offset_individual(y) = numel(compiledData{y,1})+numel(compiledData{y,2})+numel(compiledData{y,3});
        end
end

if fullCell
    % Add some extra margin
    x = [compiledData{end,:}];
    offset_y = ceil(max(cellfun(@numel, x))/2);
    img_map = nan(sY+offset_y+1, sX);
else
    img_map = nan(sY, sX);
end

if fullCell
    row_px = 0;
    ticks = zeros(size(compiledData, 1), 1);
    for y = 1:size(compiledData, 1)
        x = [compiledData{y,:}];
        
        % Space between the cells
        offset_y = ceil(max(cellfun(@numel, x))/2);
        
        if y == 1
            row_px = row_px + offset_y+1;
        else
            row_px = row_px + offset_y+offset_y_previous+1;
        end
        for xi = 1:numel(x)
            img_map((row_px-ceil(numel(x{xi})/2)+2):(row_px+floor(numel(x{xi})/2)+1), (offset-offset_individual(y)+xi)) = x{xi};
        end
        ticks(y) = row_px+1;
        offset_y_previous = offset_y;
    end
else
    for y = 1:size(compiledData, 1)
        x = [compiledData{y,:}];
        img_map(y, (offset-offset_individual(y)):(offset-offset_individual(y)+numel(x)-1)) = x;
    end
    ticks = 1:size(compiledData, 1);
end

