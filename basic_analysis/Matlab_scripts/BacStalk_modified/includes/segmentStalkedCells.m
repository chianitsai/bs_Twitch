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

%
% INPUT
%   required parameters:
%       o img - cell array containing images (channels)
%
%   optional parameters:
%       o cells - cell structure of segmented cells, if provided NO SEGMENTATION IS PERFORMED
%       o channelName - cell array (default: 'ch1') - channel name is appended to measurement names; the number of channel names has to match the number of images
%       o expandMedialAxis [boolean] (default: false) - if set to true, the medial axis will we expanded to the cell outline
%       o ROI - regio of interest (x, y, w, h) [in px]
%       o scaling - pixel size in micron (default: 1 micron)
%       o cellSize - typical cell diameter [in px] (default: 10 px)
%       o minCellSize - min cell size [in px] (default: 20 px)
%       o detectStalks - turn stalk/bud detection on/off [boolean] (default: on)
%       o stalkScreeningLength - max stalk length [in px] (default: 50 px)
%       o open stalkScreeningWidth - width of stalk fourescence minima [in px] (default: 3 px)
%       o stalkRigidity - maximum allowed flexibility [stalk-length/stalk end-to-end distance] (default: 2)
%       o cellExpansionWidth - cell is expanded by this length to search for the stalk attachment point [in px] (default: 3 px)
%       o stalkSensitivity - 0.1-10: sensitivity of stalk propagation, 0.1: high sensitivity, 2: low sensitivity (default: 1)
%       o excludeCellsCloseBy - delete cells which are closer than "cellExpansionWidth" [boolean] (default: true)
%       o detectBuds - enable/disable bad detection [boolean] (default: true)
%       o tform - affine2d image registration information (default: [])
%       o debugging - shows debugging information [boolean] (default: false)
%       o cellBackground - type of cell-image background ['bright' or 'dark'] (default: 'bright')
%       o stalkBackground - type of stalk-image background ['bright' or 'dark'] (default: 'bright')
%       o cellChannel - id of channel containg cells
%       o stalkChannel - id of channel containg stalks
%       o useBinaryMasks - enable/disable image preprocessing prior to segmentation [boolean] (default: false)
%
% OUTPUT
%   structure containing cell data
%       o StalkIdx: Idx of stalk starting at the cell
%       o StalkCoordinates: Coordinates of stalk starting at the cell
%%

function cells = segmentStalkedCells(img, varargin)

% Parse input parameters
p = inputParser;

addRequired(p,'img');
addParameter(p,'cells', []);
addParameter(p,'expandMedialAxis', false);
addParameter(p,'channelName', 'PhaseContrast');
addParameter(p,'plotCells', false);
addParameter(p,'ROI', []);
addParameter(p,'cellSize', 10);
addParameter(p,'scaling', 1);
addParameter(p,'minCellSize', 5);
addParameter(p,'detectStalks', true);
addParameter(p,'minStalkLength', 5);
addParameter(p,'stalkScreeningLength', 150);
addParameter(p,'stalkRigidity', 2);
addParameter(p,'stalkScreeningWidth', 3);
addParameter(p,'cellExpansionWidth', 3);
addParameter(p,'debugging', false);
addParameter(p,'stalkSensitivity', 1);
addParameter(p,'detectBuds', true);
addParameter(p,'excludeCellsCloseBy', true);
addParameter(p,'tform', []);
addParameter(p,'worker', 1);
addParameter(p,'cellBackground', 'bright');
addParameter(p,'stalkBackground', 'bright');
addParameter(p,'cellChannel', 1);
addParameter(p,'stalkChannel', 1);
addParameter(p,'useBinaryMasks', false);

parse(p,img,varargin{:});

% Assign parameters
ROI = p.Results.ROI;
cells = p.Results.cells;
expandMedialAxis = p.Results.expandMedialAxis;
channelName = p.Results.channelName;
plotCells = p.Results.plotCells;
tform = p.Results.tform;

% Check input
if ~iscell(img)
    img = {img};
end
if ~iscell(channelName)
    channelName = {channelName};
end
if numel(channelName) ~= numel(img)
    channelName = cellfun(@(x) sprintf('ch%d', x), num2cell(1:numel(img)), 'UniformOutput', false);
    channelName{1} = 'PhaseContrast';
end

% Correct shift
if ~isempty(cells) && ~isempty(cells.Parameters.tform)
    tform = cells.Parameters.tform;
end

% Convert RGB image to grayscale and to double & correct shift
for i = 1:numel(img)
    if size(img{i}, 3) > 1
        % Convert to gray-scale
        img{i} = rgb2gray(img{i});
    end
    img{i} = double(img{i});
    
    if ~isempty(tform)
        img{i} = imwarp(img{i}, tform, 'OutputView', imref2d(size(img{i})), 'Interp', 'linear', 'FillValues', mean(img{i}(:)));
    end
end



if isempty(cells) % do segmentation
    cellSize = p.Results.cellSize;
    scaling = p.Results.scaling;
    minCellSize = p.Results.minCellSize;
    detectStalks = p.Results.detectStalks;
    minStalkLength = p.Results.minStalkLength;
    stalkScreeningLength = p.Results.stalkScreeningLength;
    stalkScreeningWidth = p.Results.stalkScreeningWidth;
    cellExpansionWidth = p.Results.cellExpansionWidth;
    debugging = p.Results.debugging;
    maxStalkDist = round(1.5*p.Results.stalkScreeningWidth); % Obsolete
    stalkSensitivity = p.Results.stalkSensitivity;
    detectBuds = p.Results.detectBuds;
    excludeCellsCloseBy = p.Results.excludeCellsCloseBy;
    stalkRigidity = p.Results.stalkRigidity;
    worker = p.Results.worker;
    cellBackground = p.Results.cellBackground;
    stalkBackground = p.Results.stalkBackground;
    cellChannel = p.Results.cellChannel;
    stalkChannel = p.Results.stalkChannel;
    useBinaryMasks = p.Results.useBinaryMasks;
    
    stalkScreeningLength = round(stalkScreeningLength/stalkScreeningWidth);
    
    cellImage = img{cellChannel};
    stalkImage = img{stalkChannel};
    
    % Invert images based in background type
    if strcmpi(cellBackground, 'dark')
        cellImage = 1-cellImage;
        stalkImage = 1-stalkImage;
    end
    if strcmpi(stalkBackground, 'dark')
        stalkImage = 1-stalkImage;
    end
    
    if debugging; tic; end
    
    % Crop image to get rid of edge effects
    cropSizeCells = 5*cellSize;
    
    % Take ROI
    if ~isempty(ROI)
        temp = true(size(cellImage));
        temp(ROI(2):(ROI(2)+ROI(4)),...
            ROI(1):(ROI(1)+ROI(3))) = false;
        cellImage(temp) = mean(cellImage(:));
    end
    
    % Filter input images
    if ~useBinaryMasks
        img_filtered = bpass(cellImage, cellSize, 1);
    else
        cellImage = 1-cellImage;
        img_filtered = cellImage;
    end
    
    % Get rid of colonies
    img_filtered_colonies = imdilate(img_filtered, strel('diamond', 3));
    
    % Crop image to get rid of edge effects
    cropSizeStalks = 5*stalkScreeningWidth;
    img_filtered = img_filtered(cropSizeCells+1:end-cropSizeCells, cropSizeCells+1:end-cropSizeCells);
    img_filtered_colonies = img_filtered_colonies(cropSizeCells+1:end-cropSizeCells, cropSizeCells+1:end-cropSizeCells);
    cellImage = cellImage(cropSizeCells+1:end-cropSizeCells, cropSizeCells+1:end-cropSizeCells);
    
    % Threshold image
    if ~useBinaryMasks
        thresh = multithresh(img_filtered);
    else
        thresh = 0;
    end
    img_bw = img_filtered>thresh;
    
    % Threshold colony image and remove colonies
    thresh = multithresh(img_filtered_colonies);
    img_bw_colonies = imdilate(img_filtered_colonies>thresh, strel('diamond', 3));
    img_bw_colonies = bwareaopen(img_bw_colonies, round(5*pi*cellSize^2));
    img_bw(img_bw_colonies) = 0;
    
    % Remove cells touching border
    img_bw = imclearborder(img_bw);
    
    % Pad images
    cellImage = padarray(cellImage, [cropSizeCells cropSizeCells], 'pre', 'replicate');
    cellImage = padarray(cellImage, [cropSizeCells cropSizeCells], 'post', 'replicate');
    img_filtered = padarray(img_filtered, [cropSizeCells cropSizeCells], 'pre', 'replicate');
    img_filtered = padarray(img_filtered, [cropSizeCells cropSizeCells], 'post', 'replicate');
    img_bw = padarray(img_bw, [cropSizeCells cropSizeCells], 0, 'pre');
    img_bw = padarray(img_bw, [cropSizeCells cropSizeCells], 0, 'post');
    
    % Calculate image size
    imSize = size(cellImage);
    
    % Remove cells on border if ROI is active
    if ~isempty(ROI)
        side1 = find(img_bw(ROI(2)+ROI(4), :));
        if ~isempty(side1)
            side1 = sub2ind(imSize, repmat(ROI(2)+ROI(4), numel(side1), 1), side1');
        else
            side1 = side1';
        end
        
        side2 = find(img_bw(ROI(2), :));
        if ~isempty(side2)
            side2 = sub2ind(imSize, repmat(ROI(2), numel(side2), 1), side2');
        else
            side2 = side2';
        end
        
        side3 = find(img_bw(:, ROI(1)+ROI(3)));
        if ~isempty(side3)
            side3 = sub2ind(imSize, side3, repmat(ROI(1)+ROI(3), numel(side3), 1));
        end
        
        side4 = find(img_bw(:, ROI(1)));
        if ~isempty(side4)
            side4 = sub2ind(imSize, side4, repmat(ROI(1), numel(side4), 1));
        end
        
        touchingPixels = [side1; side2; side3; side4];
        
        if ~isempty(touchingPixels)
            img_bw = ~imfill(~img_bw, touchingPixels);
        end
    end
    
    
    
    % Remove small objects
    img_bw = bwareaopen(img_bw, 20);
    
    % Fill holes
    img_bw = imfill(img_bw, 'holes');
    
    % Identify cells
    cells = bwconncomp(img_bw);
    
    % Storing segmentation parameters in output
    parameters = setdiff(fieldnames(p.Results), 'img');
    for param = 1:numel(parameters)
        cells.Parameters.(parameters{param}) = p.Results.(parameters{param});
    end
    
    
    
    % Remove cells with skeleton branches
    im_skel = bwmorph(img_bw>0,'thin','inf');
    branchpoints = find(bwmorph(im_skel,'branchpoints'));
    removeObject = false(cells.NumObjects, 1);
    for c = 1:cells.NumObjects
        if ~isempty(intersect(cells.PixelIdxList{c}, branchpoints))
            removeObject(c) = true;
        end
    end
    
    cells.PixelIdxList(removeObject) = [];
    cells.NumObjects = sum(removeObject == false);
    
    %[~, areaSortIdx] = sort(cellfun(@numel, cells.PixelIdxList), 'descend');
    %cells.PixelIdxList = cells.PixelIdxList(areaSortIdx);
    if cells.NumObjects == 0
        cells.Stats = [];
        fprintf('[WORKER %d] No cells found!\n', worker);
        return;
    end
    
    fprintf('[WORKER %d] Ignoring %d/%d (%0.1f%%) objects (clumped cells)\n', worker, sum(removeObject), cells.NumObjects, sum(removeObject)/cells.NumObjects*100);
    
    
    cells.Stats = regionprops(cells, 'Centroid', 'Area', 'MinorAxisLength', 'Orientation');
    
    CellID = num2cell(1:cells.NumObjects);
    FalseArray = num2cell(false(1, cells.NumObjects));
    emptyCellArray = cell(1, cells.NumObjects);
    [cells.Stats.CellID] = CellID{:};
    [cells.Stats.CellDeleted] = FalseArray{:};
    [cells.Stats.Bud] = FalseArray{:};
    [cells.Stats.Comment] = emptyCellArray{:};
    [cells.Stats.Stalk] = FalseArray{:};
    [cells.Stats.StalkIdx] = emptyCellArray{:};
    [cells.Stats.StalkCoordinates] = emptyCellArray{:};
    [cells.Stats.ConnectedWith] = emptyCellArray{:};
    [cells.Stats.StalkLength] = emptyCellArray{:};
    [cells.Stats.StalkTouchesEdge] = emptyCellArray{:};
    [cells.Stats.CellMedialAxisIdx] = emptyCellArray{:};
    [cells.Stats.CellMedialAxisCoordinates] = emptyCellArray{:};
    
    cells_labelled = labelmatrix(cells);
    
    % Expand labelled cells
    cells_labelled_expanded = cells_labelled;
    for c = 1:max(cells_labelled_expanded(:))
        for i = 1:cellExpansionWidth
            cellExpandedIdx = neighbourND(find(cells_labelled_expanded == c), imSize);
            cells_labelled_expanded(cellExpandedIdx) = c;
            
            if i == 1
                cellExpandedIdx_cellDeletion = cellExpandedIdx;
            end
        end
        
        % Cell shell
        idxExpandedCell = find(cells_labelled_expanded == c);
        idxCellShell = setdiff(idxExpandedCell, cells.PixelIdxList{c});
        intCellShell = mean(stalkImage(idxCellShell));
        stalkImage(cellExpandedIdx_cellDeletion) = intCellShell;
    end
    
    %cellIdxAll = find(cells_labelled_expanded>0);
    cellIdxAll = find(cells_labelled>0);
    img_clumpedStructures = img_bw;
    img_clumpedStructures(cells_labelled>0) = 0;
    cellIdsClumped = find(img_clumpedStructures);
    
    % Prepare stalk input image
    stalkImage = bpass(stalkImage, stalkScreeningWidth, 1);
    
    stalkImage = stalkImage(cropSizeStalks+1:end-cropSizeStalks, cropSizeStalks+1:end-cropSizeStalks);
    stalkImage = padarray(stalkImage, [cropSizeStalks cropSizeStalks], 'pre', 'replicate');
    stalkImage = padarray(stalkImage, [cropSizeStalks cropSizeStalks], 'post', 'replicate');
    stalkImage(cells_labelled>0) = max(stalkImage(:));
    
    % Create labelled image if debugging is on
    if debugging
        
        cmap = gray(255);            % 0-249: cell intensity image
        cmap(250,:) = [0 1 1];       % 250:   clumped structure
        cmap(251,:) = [1 1 1];       % 251:   cell outlines
        cmap(252,:) = [0 1 0];       % 252:   stalk
        cmap(253,:) = [0 0 1];       % 253:   stalk endpoint (to dim)
        cmap(254,:) = [1 1 0];       % 254:   bad stalk
        cmap(255,:) = [1 0 0];       % 255:   stalk hit cell
        cmap(256,:) = [0.5 0.5 0.5]; % 256:   stalk search area
        
        img_overlay = 249*cellImage/max(cellImage(:));
        img_overlay(bwperim(img_clumpedStructures)) = 250;
    end
    
    cell_outline = cell(1, cells.NumObjects);
    
    
    
    
    for c = 1:cells.NumObjects
        
        if debugging; fprintf('Finding stalk of cell %d\n', c); end
        
        cells.Stats(c).Stalk = false;
        cells.Stats(c).StalkIdx = [];
        cells.Stats(c).StalkCoordinates = [];
        
        connectedToCellID = [];
        stalkTouchesEdge = [];
        
        % Isolating cell c
        img_cell_selected = cells_labelled == c;
        img_cell_selected_dilated = img_cell_selected;
        cell_outline{c} = neighbourND(find(img_cell_selected), imSize);
        img_cell_selected_dilated(cell_outline{c}) = 1;
        
        cell_outline{c} = setxor(cell_outline{c}, find(img_cell_selected));
        if debugging
            img_overlay(cell_outline{c}) = 251;
        end
        
        if ~detectStalks
            continue;
        end
        
        % Expand the cell outlines
        for i = 1:cellExpansionWidth
            img_cell_selected_dilated(neighbourND(find(img_cell_selected_dilated), imSize)) = 1;
        end
        
        % Initializing stalk
        stalk = zeros(stalkScreeningLength, 1);
        
        % Propagating stalk by finding the local minima of shells around the
        % cell
        cell_idx = find(img_cell_selected_dilated);
        cell_shell = unique(neighbourND(cell_idx, imSize));
        shell_idx = setxor(cell_shell, cell_idx);
        
        %shell_idxRef = unique(neighbourND(shell_idx, imSize));
        %shell_idxRef = setdiff(shell_idxRef, cell_shell);
        
        intValuesReference = stalkImage(shell_idx);
        
        % Determine shell intensity values
        intValues = stalkImage(shell_idx);
        
        % Check if stalk minima is deep enough
        [stalkIdx, goodStalk] = checkStalk(intValues, shell_idx, intValuesReference, stalkSensitivity);
        if goodStalk
            s = 1;
            %             % Check if first point already hits another cell
            %             if ~isempty(find(stalkIdx == cellIdxAll, 1))
            %                 %cells.Stats(c).CellDeleted = true;
            %                 if debugging; fprintf('   cell too close by\n'); end
            %                 continue;
            %             end
            
            stalk(1) = stalkIdx;
            if debugging; fprintf('   stalk found\n'); end
            if debugging; img_overlay(stalkIdx) = 252; end
            
            % Calculating the inital stalk length by calculating the distance
            % to the cell outline
            [x_stalk, y_stalk] = ind2sub(imSize, stalkIdx);
            [x_shell, y_shell] = ind2sub(imSize, cell_outline{c});
            dist = hypot(x_stalk-x_shell, y_stalk-y_shell);
            
            % Identify the stalk start point by locating the point on the
            % cell outline most nearby
            [stalk_length, stalkStartIdx] = min(dist);
            stalkStartIdx = cell_outline{c}(stalkStartIdx);
            
            % Interpolate points in between
            [x_prev, y_prev] = ind2sub(imSize, stalkStartIdx);
            %x_int = round(linspace(x_prev, x_stalk, ceil(1.42*stalk_length)));
            %y_int = round(linspace(y_prev, y_stalk, ceil(1.42*stalk_length)));
            [x_int, y_int] = drawLine(x_prev, y_prev, x_stalk, y_stalk);
            stalkIdxAll = unique(sub2ind(imSize, x_int, y_int));
            
        else
            % Stalk ended
            if debugging
                fprintf('   stalk ended\n');
                img_overlay(stalkIdx) = 254;
            end
            continue;
        end
        
        % If clumped structure is hit -> delete cell
        touchingClumpedStructure = find(stalkIdx == cellIdsClumped, 1);
        if ~isempty(touchingClumpedStructure)
            cells.Stats(c).CellDeleted = true;
            cells.Stats(c).Comment = sprintf('%sTouching clumped structure. ', cells.Stats(c).Comment);
            
            if debugging; fprintf('   touching clumped structure%d\n', connectedToCellID); end
        else
            
            % If cell is hit -> stop, otherwise propagate stalk
            touchingCell = find(stalkIdx == cellIdxAll, 1);
            if ~isempty(touchingCell)
                % Stalk hit another cell
                img_overlay(stalkIdx) = 255;
                
                stalkIdxAll = setdiff(stalkIdxAll, cellIdxAll);
                % Find the other cell
                connectedToCellID = cells_labelled(cellIdxAll(touchingCell));
                
                % Delete both cells
                if excludeCellsCloseBy
                    cells.Stats(c).CellDeleted = true;
                    cells.Stats(c).Comment = sprintf('%sCell %d is too close by. ', cells.Stats(c).Comment, connectedToCellID);
                    cells.Stats(connectedToCellID).CellDeleted = true;
                    %cells.Stats(connectedToCellID).Comment = sprintf('%sCell %d is too close by. ', cells.Stats(connectedToCellID).Comment, c);
                end
                
                if debugging; fprintf('   hit cell %d\n', connectedToCellID); end
                
                
            else % Propagate stalk
                for s = 2:stalkScreeningLength
                    % Expand the stalk end tip 2 times
                    stalk_expanded_new = stalkIdx;
                    for i = 1:stalkScreeningWidth
                        stalk_expanded_new = neighbourND(unique(stalk_expanded_new), imSize);
                    end
                    stalk_expanded_new = unique(stalk_expanded_new);
                    
                    % Remove stalk indices which belong to cell
                    stalk_idx_measure = setdiff(stalk_expanded_new, cell_shell);
                    
                    % Break if stalk stops
                    if isempty(stalk_idx_measure)
                        break;
                    end
                    if ~stalk_idx_measure
                        break;
                    end
                    
                    % Update already processed area
                    cell_shell = union(cell_shell, stalk_expanded_new);
                    
                    % Visualize processed area
                    % if debugging; img_overlay(stalk_expanded_new) = 256; end
                    
                    % Determine shell intensity values
                    intValues = stalkImage(stalk_idx_measure);
                    
                    intValuesReference = [intValuesReference(:); intValues(1:2:end)];
                    
                    % Check if stalk minima is deep enough
                    [stalkIdx, goodStalk] = checkStalk(intValues, stalk_idx_measure, intValuesReference, stalkSensitivity);
                    % fprintf('   %d ', stalkIdx);
                    
                    % Check if stalk minima is connected to last minima
                    [x, y] = ind2sub(imSize, [stalk(s-1), stalkIdx]);
                    dist = hypot(x(2)-x(1), y(2)-y(1));
                    stalk_length = stalk_length + dist;
                    
%                     if dist > maxStalkDist
%                         cells.Stats(c).Comment = sprintf('%sMax stalk distance reached. ', cells.Stats(c).Comment);
%                         if debugging
%                             fprintf('   ended (to random)\n');
%                             img_overlay(stalkIdx) = 254;
%                         end
%                         stalk = 0;
%                         break;
%                     end
                    
                    % Corner of image is reached
                    [x, y] = ind2sub(imSize, stalkIdx);
                    if x < cropSizeStalks || x > (imSize(1)-cropSizeStalks) || y < cropSizeStalks || y > (imSize(2)-cropSizeStalks)
                        if debugging
                            cells.Stats(c).Comment = sprintf('%sStalk touching border of image. ', cells.Stats(c).Comment);
                            fprintf('   ended (touching border of image)\n');
                            img_overlay(stalkIdx) = 254;
                        end
                        stalkTouchesEdge = true;
                        break;
                    else
                        stalkTouchesEdge = false;
                    end
                    
                    if goodStalk
                        % Interpolate missing stalk indices
                        [x_prev, y_prev] = ind2sub(imSize, stalk(s-1));
                        %x_int = round(linspace(x_prev, x, ceil(1.42*dist)));
                        %y_int = round(linspace(y_prev, y, ceil(1.42*dist)));
                        [x_int, y_int] = drawLine(x_prev, y_prev, x, y);
                        
                        stalkIdxAll = union(stalkIdxAll, sub2ind(imSize, x_int, y_int));
                        
                        stalk(s) = stalkIdx;
                        
                        touchingCell = find(stalkIdx == cellIdxAll, 1);
                        if ~isempty(touchingCell)
                            % Stalk hit another cell
                            img_overlay(stalkIdx) = 255;
                            
                            stalkIdxAll = setdiff(stalkIdxAll, cellIdxAll);
                            connectedToCellID = cells_labelled(cellIdxAll(touchingCell));
                            
                            % Find the other cell
                            if debugging; fprintf('   hit cell %d\n', connectedToCellID); end
                            break;
                        else
                            if debugging; img_overlay(stalkIdx) = 252; end
                        end
                        
                        % If clumped structure is hit -> delete cell
                        touchingClumpedStructure = find(stalkIdx == cellIdsClumped, 1);
                        if ~isempty(touchingClumpedStructure)
                            cells.Stats(c).CellDeleted = true;
                            cells.Stats(c).Comment = sprintf('%sTouching clumped structure. ', cells.Stats(c).Comment);
                            if debugging; fprintf('   touching clumped structure%d\n', connectedToCellID); end
                            break;
                        end
                        
                    else
                        % Stalk ended
                        if debugging
                            fprintf('   ended (to dim)\n');
                            img_overlay(stalk(s-1)) = 253;
                        end
                        break;
                    end
                    
                    % If the loop as proceeded until the last index add
                    % comment that max. stalk length has been reached
                    if s == stalkScreeningLength
                        cells.Stats(c).Comment = sprintf('%sMax stalk screening length reached (%d px). ', cells.Stats(c).Comment, stalkScreeningLength*stalkScreeningWidth);
                        if debugging
                             fprintf('   ended (max screening length reached)\n');
                             img_overlay(stalkIdx) = 254;
                         end
                    end
                end
            end
            
            if debugging; fprintf('   stalk-length: %d steps\n', s); end
            stalk(~stalk) = [];
            %[x, y] = ind2sub(imSize, stalk);
            %plot(gca, y, x, 'Color', 'green');
        end
        
        try
            stalkIdxAll = sortIdx(imSize, stalkIdxAll, stalkStartIdx);
        catch
            fprintf('Error with stalk of cell %d!\n', c)
            stalkIdxAll = stalkIdxAll';
        end
        
        % Obtaining stalk coordinates
        [stalkCoordX, stalkCoordY] = ind2sub(imSize, stalkIdxAll);
        [stalkCoordX, stalkCoordY] = smoothLine(stalkCoordX, stalkCoordY);
        
        % Calculate stalk length
        d = diff([stalkCoordX stalkCoordY]);
        stalk_length = sum(sqrt(sum(d.*d,2)));
        
        % Check stalk length
        if stalk_length >= minStalkLength
            
            % Check stalk rigidity
            endpointDistance = hypot(stalkCoordX(end)-stalkCoordX(1), stalkCoordY(end)-stalkCoordY(1));
            
            if stalk_length < stalkRigidity*endpointDistance
                cells.Stats(c).Stalk = ~isempty(stalk);
                cells.Stats(c).StalkTouchesEdge = stalkTouchesEdge;
                
                if ~detectBuds
                    connectedToCellID = [];
                end
                
                cells.Stats(c).ConnectedWith = connectedToCellID;
                cells.Stats(c).StalkLength = stalk_length;
                
                %[sampled_outline] = sampleOutline([stalkCoordX, stalkCoordY]);
                %stalkCoordX = [stalkCoordX(1); sampled_outline(1:end-1,1); stalkCoordX(end)];
                %stalkCoordY = [stalkCoordY(1); sampled_outline(1:end-1,2); stalkCoordY(end)];
                %%[stalkCoordX, stalkCoordY] = bezierCurve(stalkCoordX, stalkCoordY);
                stalkIdxAll = sub2ind(imSize, stalkCoordX, stalkCoordY);
                
                cells.Stats(c).StalkIdx = stalkIdxAll;
                [stalkCoordX, stalkCoordY] = ind2sub(imSize, stalkIdxAll);
                cells.Stats(c).StalkCoordinates = [stalkCoordX, stalkCoordY];
            else
                if debugging; fprintf('     -> stalk is too bended (length: %.1f, endpoint-distance: %.1f)\n', stalk_length, endpointDistance); end
            end
        else
            if debugging; fprintf('     -> stalk is too short\n'); end
        end
        
        
    end
    
    
    %Check stalk connections
    if detectBuds
        
        if debugging; fprintf('Checking stalk connections\n'); end
        cellProcessed = false(1, cells.NumObjects);
        
        % Sort cells by area to start with non-buds
        [~, areaSortIdx] = sort([cells.Stats.Area], 'descend');
        
        stalkIdx = {cells.Stats.StalkIdx};
        for cIdx = 1:cells.NumObjects
            c = areaSortIdx(cIdx);
            if ~isempty(cells.Stats(c).StalkIdx) && ~cellProcessed(c)
                connections = find(cellfun(@(x, y) ~isempty(intersect(x, y)), stalkIdx, repmat({cells.Stats(c).StalkIdx}, 1, cells.NumObjects)));
                connections = setdiff(connections, c);
                if ~isempty(connections)
                    cells.Stats(c).ConnectedWith = connections(1);
                    
                    % Check wether cell which this cell is already processed
                    % and connected
                    if cellProcessed(connections(1)) && ...
                            cells.Stats(connections(1)).ConnectedWith ~= c
                        
                        if cells.Stats(connections(1)).Bud
                            cells.Stats(c).Comment = ...
                                sprintf('%sUnclear link (1): connected to cell #%d, but this cell already has a bud (#%d). ', cells.Stats(c).Comment, cells.Stats(c).ConnectedWith, cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith);
                        else
                            cells.Stats(c).Comment = ...
                                sprintf('%sUnclear link (2): connected to cell #%d, but this cell is also stalked by cell #%d. ', cells.Stats(c).Comment, cells.Stats(c).ConnectedWith, cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith);
                            
                        end
                        
                        cells.Stats(cells.Stats(c).ConnectedWith).Comment = ...
                            sprintf('%s(?) Unclear: stalk might be wrong due to close proximity of cell %d. ', cells.Stats(cells.Stats(c).ConnectedWith).Comment, c);
                        
                        cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment = ...
                            sprintf('%s(?) Unclear: stalk might be wrong due to close proximity of cell %d. ', cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment, c);
                        
                        
                        % Remove also the other cells involved.
                        %                     cells.Stats(cells.Stats(c).ConnectedWith).CellDeleted = true;
                        %                      cells.Stats(cells.Stats(c).ConnectedWith).Comment{end+1} = ...
                        %                          sprintf('Deleted: unclear link; stalked by cell #%d, but being connected to cell #%d!', c, cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith);
                        %
                        %                     cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).CellDeleted = true;
                        %
                        %                      cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment{end+1} = ...
                        %                          sprintf('Deleted: unclear link; connected to cell #%d, but this cell is also stalked by cell #%d!', cells.Stats(c).ConnectedWith, c);
                        
                        cells.Stats(c).Bud = false;
                        cells.Stats(c).CellDeleted = true;
                        cells.Stats(c).Stalk = false;
                        cells.Stats(c).StalkLength = [];
                        cells.Stats(c).ConnectedWith = [];
                        
                        cellProcessed(c) = true;
                        continue;
                    end
                    
                    cells.Stats(connections(1)).ConnectedWith = c;
                    
                    % Walk along stalk and find first intersection with other
                    % stalk and clean up stalks
                    
                    % The direction should always be from mother to budding
                    % cell
                    if cells.Stats(c).Area >= cells.Stats(connections(1)).Area
                        bud = connections(1);
                        motherCell = c;
                    else
                        bud = c;
                        motherCell = connections(1);
                    end
                    
                    cellProcessed(bud) = true;
                    cellProcessed(motherCell) = true;
                    
                    for s = 1:numel(cells.Stats(motherCell).StalkIdx)
                        % The intersection is from budding cell -> mother cell
                        try
                            intersectionPoint = find(cells.Stats(bud).StalkIdx == cells.Stats(motherCell).StalkIdx(s));
                        catch
                            intersectionPoint = [];
                            fprintf('Check cell %d\n', motherCell)
                        end
                        if ~isempty(intersectionPoint)
                            % Invert budding cell stalk idx order
                            stalkIdxCombined = [cells.Stats(motherCell).StalkIdx(1:s-1); flip(cells.Stats(bud).StalkIdx(1:intersectionPoint))];
                            
                            % Regenerate the stalk coordinates
                            cells.Stats(motherCell).StalkIdx = stalkIdxCombined;
                            [stalkCoordX, stalkCoordY] = ind2sub(imSize, stalkIdxCombined);
                            cells.Stats(motherCell).StalkCoordinates = [stalkCoordX, stalkCoordY];
                            
                            cells.Stats(bud).Bud = true;
                            cells.Stats(bud).StalkIdx = flip(stalkIdxCombined);
                            cells.Stats(bud).Stalk = true;
                            cells.Stats(bud).StalkLength = [];
                            cells.Stats(bud).StalkCoordinates = flip([stalkCoordX, stalkCoordY]);
                            
                            % If budding cell, medial axis has to be inverted!
                            % cells.Stats(bud).CellMedialAxisIdx = flip(cells.Stats(bud).CellMedialAxisIdx);
                            % cells.Stats(bud).CellMedialAxisCoordinates = flip(cells.Stats(bud).CellMedialAxisCoordinates);
                            
                            
                            % Find stalk length
                            [x_stalk, y_stalk] = ind2sub(imSize, stalkIdxCombined);
                            d = diff([x_stalk(:) y_stalk(:)]);
                            stalkLength = sum(sqrt(sum(d.*d,2)));
                            
                            cells.Stats(motherCell).StalkLength = stalkLength*scaling;
                            break;
                        end
                    end
                else % Stalks are not touching, check if cells are connected
                    if ~isempty(cells.Stats(c).ConnectedWith) % Cell is connected
                        if ~isempty(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith)
                            if c == cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith
                                % Cells are connected but stalks of cells don't hit each other
                                % -> assign stalk of mother cell
                                connections = cells.Stats(c).ConnectedWith;
                                
                                if cells.Stats(c).Area >= cells.Stats(connections(1)).Area
                                    bud = connections(1);
                                    motherCell = c;
                                else
                                    bud = c;
                                    motherCell = connections(1);
                                end
                                
                                cellProcessed(bud) = true;
                                cellProcessed(motherCell) = true;
                                
                                cells.Stats(bud).StalkIdx = flip(cells.Stats(motherCell).StalkIdx);
                                cells.Stats(bud).Stalk = true;
                                cells.Stats(bud).StalkLength = [];
                                cells.Stats(bud).StalkCoordinates = flip(cells.Stats(motherCell).StalkCoordinates);
                                cells.Stats(bud).Bud = true;
                                
                                % In theory the medial axis might not match the stalk now!
                                % cells.Stats(bud).Comment{end+1} = 'Deleted cell: medial axis might be wrong';
                                
                                % If budding cell, medial axis has to be inverted!
                                % cells.Stats(bud).CellMedialAxisIdx = flip(cells.Stats(bud).CellMedialAxisIdx);
                                % cells.Stats(bud).CellMedialAxisCoordinates = flip(cells.Stats(bud).CellMedialAxisCoordinates);
                                
                            else
                                % Cell #c is connected to a budding cell but
                                % budding cell is connected to another cell ->
                                % delete both cells
                                cellProcessed(c) = true;
                                
                                cells.Stats(c).Comment = ...
                                    sprintf('%sUnclear link (3): connected to cell #%d, but this cell is connected to cell #%d. ', cells.Stats(c).Comment, cells.Stats(c).ConnectedWith, cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith);
                                
                                % Only delete other cells if they have not been
                                % processed, yet
                                if ~cellProcessed(cells.Stats(c).ConnectedWith) && ~cellProcessed(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith)
                                    
                                    cellProcessed(cells.Stats(c).ConnectedWith) = true;
                                    cellProcessed(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith) = true;
                                    
                                    cells.Stats(cells.Stats(c).ConnectedWith).CellDeleted = true;
                                    cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).CellDeleted = true;
                                    
                                    cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment = ...
                                        sprintf('%sUnclear link (4): connected to cell #%d, but this cell is also stalked by cell #%d. ', cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment, cells.Stats(c).ConnectedWith, c);
                                    
                                    cells.Stats(cells.Stats(c).ConnectedWith).Comment = ...
                                        sprintf('%sUnclear link (5): connected to cell #%d and #%d. ', cells.Stats(cells.Stats(c).ConnectedWith).Comment, c, cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith);
                                    
                                else
                                    cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment = ...
                                        sprintf('%s(?) Unclear: stalk might be wrong due to close proximity of cell %d. ', cells.Stats(cells.Stats(cells.Stats(c).ConnectedWith).ConnectedWith).Comment, c);
                                    
                                    cells.Stats(cells.Stats(c).ConnectedWith).Comment = ...
                                        sprintf('%s(?) Unclear: stalk might be wrong due to close proximity of cell %d. ', cells.Stats(cells.Stats(c).ConnectedWith).Comment, c);
                                    
                                end
                                
                                cells.Stats(c).CellDeleted = true;
                                cells.Stats(c).StalkLength = [];
                                cells.Stats(c).Stalk = false;
                                cells.Stats(c).ConnectedWith = [];
                            end
                        else % Only one stalk is present
                            % Check if stalk is correctly assinged to mother cell
                            connections = cells.Stats(c).ConnectedWith;
                            
                            if cells.Stats(c).Area >= cells.Stats(connections(1)).Area
                                % Everything is correct
                                bud = connections(1);
                                motherCell = c;
                                
                                cells.Stats(bud).ConnectedWith = motherCell;
                                
                                % Take stalk from cell c and put it to other cell
                                cells.Stats(bud).StalkIdx = flip(cells.Stats(c).StalkIdx);
                                cells.Stats(bud).StalkCoordinates = flip(cells.Stats(c).StalkCoordinates);
                                cells.Stats(bud).Bud = true;
                                
                            else
                                bud = c;
                                motherCell = connections(1);
                                
                                cells.Stats(motherCell).ConnectedWith = bud;
                                
                                % Copy stalk from budding cell to mother cell
                                cells.Stats(motherCell).StalkIdx = flip(cells.Stats(bud).StalkIdx);
                                cells.Stats(motherCell).Stalk = true;
                                cells.Stats(motherCell).StalkLength = cells.Stats(bud).StalkLength;
                                cells.Stats(motherCell).StalkCoordinates = flip(cells.Stats(bud).StalkCoordinates);
                                cells.Stats(bud).Bud = true;
                                
                                % Delete stalk of budding cell
                                % cells.Stats(bud).StalkIdx = [];
                                % cells.Stats(bud).Stalk = false;
                                % cells.Stats(bud).StalkLength = [];
                                % cells.Stats(bud).StalkCoordinates = [];
                                % cells.Stats(bud).CellDeleted = true;
                                
                                % In theory the medial axis might not match the stalk now!
                                % Take stalk from cell c and but it to other cell
                                % cells.Stats(bud).StalkIdx = cells.Stats(motherCell).StalkIdx;
                                % cells.Stats(bud).StalkCoordinates = cells.Stats(motherCell).StalkCoordinates;
                                
                                %cells.Stats(bud).Comment{end+1} = 'Deleted cell: medial axis might be wrong';
                            end
                            
                            
                            
                            
                            % Change orientation of medial axis of budding cell
                            % cells.Stats(bud).CellMedialAxisIdx = flip(cells.Stats(bud).CellMedialAxisIdx);
                            % cells.Stats(bud).CellMedialAxisCoordinates = flip(cells.Stats(bud).CellMedialAxisCoordinates);
                        end
                        
                    end
                end
            end
        end
    end
    
    % Undo cells sorting
    % idx = 1:cells.NumObjects;
    % cells.Stats = cells.Stats(idx(areaSortIdx));
    
    % Create new PixelIdxList array which includes the stalk for
    % skeletonizing
    if debugging; fprintf('Calculating medial axes\n'); end
    PixelIdxList_withStalk = cells.PixelIdxList;
    for c = 1:cells.NumObjects
        PixelIdxList_withStalk{c} = [PixelIdxList_withStalk{c}; cells.Stats(c).StalkIdx];
    end
    
    cells_withStalk = struct('Connectivity', cells.Connectivity,...
        'ImageSize', cells.ImageSize,...
        'NumObjects', cells.NumObjects,...
        'PixelIdxList', {PixelIdxList_withStalk});
    
    cells_BW_withStalk = labelmatrix(cells_withStalk)>0;
    cells_BW_woStalk = labelmatrix(cells)>0;
    
    % This cells + stalk to line
    im_skel_withStalk = bwmorph(cells_BW_withStalk,'thin','inf');
    im_skel_woStalk = bwmorph(cells_BW_woStalk,'thin','inf');
    
    It = find(im_skel_withStalk);
    endpoints = find(bwmorph(im_skel_woStalk,'endpoints'));
    branchpoints = find(bwmorph(im_skel_withStalk,'branchpoints'));
    
    % Calculate medial cell axis
    deleteCell = false(cells.NumObjects, 1);
    for c = 1:cells.NumObjects
        
        % Check if new branchpoint was created
        cellBranchpoints = intersect(branchpoints, cells.PixelIdxList{c});
        if ~isempty(cellBranchpoints)
            %deleteCell(c) = true;
            %continue;
        end
        
        % Sometimes the start of the stalk is too far away! (has to be
        % fixed)
        cellMedialAxis = intersect(It, cells.PixelIdxList{c});
        
        
        %         if numel(cellEndpoints) > 8
        %             % delete branches
        %             fprintf('Cell %d has several branches!\n');
        %         end
        
        
        % If stalk is present sort idx values to start at cell tip and end
        % where stalk starts
        if ~isempty(cells.Stats(c).StalkIdx)
            try
                cellMedialAxis = flip(sortIdx(cells.ImageSize, cellMedialAxis, cells.Stats(c).StalkIdx(1)));
                cellMedialAxis = propagateMedialAxis(imSize, cellMedialAxis, cell_outline{c}, cells.Stats(c).MinorAxisLength, 'tip');
                cellMedialAxis = flip(sortIdx(cells.ImageSize, cellMedialAxis, cells.Stats(c).StalkIdx(1)));
            catch
                fprintf('Medial axis of cell (with stalk) %d could not be determined!\n', c);
            end
        else % propagate cell axis in both directions
            try
                endpoints_cell = intersect(cellMedialAxis, endpoints);
                % sort idx according to skeleton endpoints
                cellMedialAxis = sortIdx(cells.ImageSize, cellMedialAxis, endpoints_cell(1));
                
                [cellMedialAxis, cellOutlineIntersectionIdx] = propagateMedialAxis(imSize, cellMedialAxis, cell_outline{c}, cells.Stats(c).MinorAxisLength, 'both');
                cellMedialAxis = sortIdx(cells.ImageSize, cellMedialAxis, cellOutlineIntersectionIdx);
            catch
                fprintf('Medial axis of cell %d could not be determined!\n', c);
            end
        end
        [medialAxisCoordX, medialAxisCoordY] = ind2sub(cells.ImageSize, cellMedialAxis);
        [medialAxisCoordX, medialAxisCoordY] = smoothLine(medialAxisCoordX, medialAxisCoordY);
        
        cellMedialAxis = sub2ind(cells.ImageSize, medialAxisCoordX, medialAxisCoordY);
        
        cells.Stats(c).CellMedialAxisIdx = cellMedialAxis;
        cells.Stats(c).CellMedialAxisCoordinates = [medialAxisCoordX, medialAxisCoordY];
    end
    
    cells.PixelIdxList(deleteCell) = [];
    cells.NumObjects = sum(~deleteCell);
    cells.Stats(deleteCell) = [];
    % fprintf('Ignoring %d cells (stalk connected to side)\n', sum(deleteCell));
    
    % Generating cell outlines
    %    CellOutlineIdx = cell(cells.NumObjects, 1);
    %    CellOutlineCoordinates = cell(cells.NumObjects, 1);
    
    CellOutlineCoordinates = pixelOutline(labelmatrix(cells));
    CellOutlineIdx = cellfun(@(imSize, X) sub2ind(imSize, X(:,1), X(:,2)), repmat({imSize}, 1, numel(CellOutlineCoordinates)), CellOutlineCoordinates, 'UniformOutput', false);
    
    %    for c = 1:cells.NumObjects
    %          outlineCoords = pixelOutline(cells.PixelIdxList{c}, imSize(1), imSize(2));
    %          outlineIdx = sub2ind(imSize, outlineCoords{1}(:,1), outlineCoords{1}(:,2));
    %         outline = setxor(cells.PixelIdxList{c}, neighbourND(cells.PixelIdxList{c}, imSize));
    %         [x, y] = ind2sub(imSize, outline);
    %
    %         outlineIdx = zeros(numel(x), 1);
    %         outlineCoords = zeros(numel(x), 2);
    %
    %         %This part sorts the outline
    %         counter = 1;
    %         numElements = numel(x);
    %         outlineCoords(counter, :) = [x(1) y(1)];
    %
    %         outlineIdx(counter) = outline(1);
    %
    %         x(1) = [];
    %         y(1) = [];
    %         while counter < numElements
    %             dist = hypot(outlineCoords(counter, 1)-x, outlineCoords(counter, 2)-y);
    %             [~, minIdx] = min(dist);
    %             outlineIdx(counter+1) = outline(minIdx);
    %             outlineCoords(counter+1, :) = [x(minIdx) y(minIdx)];
    %             x(minIdx) = [];
    %             y(minIdx) = [];
    %             counter = counter + 1;
    %         end
    %
    %        CellOutlineIdx{c} = outlineIdx;
    %        CellOutlineCoordinates{c} = outlineCoords;
    %    end
    
    [cells.Stats.CellOutlineIdx] = CellOutlineIdx{:};
    [cells.Stats.CellOutlineCoordinates] = CellOutlineCoordinates{:};
    
    
    
    
    
    %     for c = 1:cells.NumObjects
    %         if ~isempty(cells.Stats(c).ConnectedWith)
    %             % cell #2
    %             c2 = cells.Stats(c).ConnectedWith;
    %             if isempty(cells.Stats(c2).ConnectedWith) % Only one cell has a connecting stalk
    %                 cells.Stats(c2).ConnectedWith = c;
    %
    %                 % Copy stalk information
    %                 cells.Stats(c2).StalkLength = cells.Stats(c).StalkLength;
    %                 cells.Stats(c2).StalkIdx = cells.Stats(c).StalkIdx;
    %                 cells.Stats(c2).Stalk = true;
    %             end
    %         end
    %     end
    %
    %     % Label budding cells
    %     for c = 1:cells.NumObjects
    %         if ~isempty(cells.Stats(c).ConnectedWith)
    %             % cell #2
    %             c2 = cells.Stats(c).ConnectedWith;
    %
    %             % Both cells have connection, remove one
    %             % Use shortest stalk
    %             if cells.Stats(c).StalkLength <= cells.Stats(c2).StalkLength
    %                 cells.Stats(c2).StalkLength = cells.Stats(c).StalkLength;
    %                 cells.Stats(c2).StalkIdx = cells.Stats(c).StalkIdx;
    %             end
    %
    %             % Determine larger cell -> mother cell
    %             if cells.Stats(c).Area >= cells.Stats(c2).Area
    %                 bud = c2;
    %             else
    %                 bud = c;
    %             end
    %
    %             cells.Stats(bud).Bud = true;
    %             cells.Stats(bud).StalkLength = [];
    %             cells.Stats(bud).StalkIdx = [];
    %             cells.Stats(bud).Stalk = false;
    %
    %         end
    %     end
    
    if debugging;
        toc;
        h = figure('Name', 'Debugging');
        h = addIcon(h);
        h_ax = axes('Parent', h, 'NextPlot', 'add');
        imagesc(img_overlay, 'parent', h_ax); colormap(cmap); set(gca, 'clim', [0 257], 'YDir', 'normal');
        if ~isempty(ROI)
            xlim(h_ax, [ROI(1) ROI(1)+ROI(3)]);
            ylim(h_ax, [ROI(2) ROI(2)+ROI(4)]);
        end
    end
    
end

% Determine length of cell outlines axes
cellOutlineLength = cellfun(@numel, {cells.Stats.CellOutlineIdx});
medialAxisLength = cellfun(@numel, {cells.Stats.CellMedialAxisIdx});

badMedialAxes = medialAxisLength < 0.25*cellOutlineLength;

connectedToCellWithBadMedialAxis = false(size(badMedialAxes));
connectedToCellWithBadMedialAxis([cells.Stats(badMedialAxes).ConnectedWith]) = true;

comments = {cells.Stats.Comment};
comments(badMedialAxes) = repmat({'Bad medial cell axis. '}, sum(badMedialAxes), 1);
comments(connectedToCellWithBadMedialAxis) = repmat({'Connected to cell with bad medial cell axis. '}, sum(connectedToCellWithBadMedialAxis), 1);
[cells.Stats.Comment] = comments{:};

badMedialAxes(connectedToCellWithBadMedialAxis) = true;
% -> Cells with bad medial axis are deleted later



% Remove stalks of budding cells
for c = 1:cells.NumObjects
    if cells.Stats(c).Bud
        cells.Stats(c).StalkIdx = [];
        cells.Stats(c).StalkCoordinates = [];
        cells.Stats(c).Stalk = false;
    end
end

% if isempty(uo) % measure Intensity properties
%     imgFluo{1} = img_input;
%     channelName{1} = 'PhaseContrast';
% end

% Create ribbons
cellLength = cell(cells.NumObjects, 1);
cellWidth = cell(cells.NumObjects, 1);
cellSinuosity = cell(cells.NumObjects, 1);

%cellStalkLength = cell(cells.NumObjects, 1);
%cellStalkBudLength = cell(cells.NumObjects, 1);

for c = 1:cells.NumObjects
    %figure; hold on;
    medialAxisCoords = cells.Stats(c).CellMedialAxisCoordinates;
    outlineCoords = cells.Stats(c).CellOutlineCoordinates;
    minorAxisLength = cells.Stats(c).MinorAxisLength;
    cZ = minorAxisLength;
    
    orientationWidths = zeros(2,1);
    
    %plot(outlineCoords(:,1), outlineCoords(:,2))
    %plot(medialAxisCoords(:,1), medialAxisCoords(:,2))
    
    ribbons{c} = cell(size(medialAxisCoords,1), 2);
    
    for m = 1:size(medialAxisCoords,1)
        smoothWindow = m-2:m+2;
        smoothWindow(smoothWindow<1 | smoothWindow>size(medialAxisCoords,1)) = [];
        % vector along medial axis
        vec1 = [medialAxisCoords(smoothWindow(1), 1) - medialAxisCoords(smoothWindow(end), 1),...
            medialAxisCoords(smoothWindow(1), 2) - medialAxisCoords(smoothWindow(end), 2)];
        vec1 = vec1/norm(vec1);
        % vector perpendicular to it
        vec2 = [-vec1(2) vec1(1)];
        % find intersection with cell outline
        ribbon = [medialAxisCoords(m, 1) + [-cZ:cZ]'*vec2(1),...
            medialAxisCoords(m, 2) + [-cZ:cZ]'*vec2(2)];
        
        % identify most likely intersections points
        pIdx = zeros(1, numel(size(ribbon, 1)));
        pDist = zeros(1, numel(size(ribbon, 1)));
        for r = 1:size(ribbon, 1)
            [pDist(r), pIdx(r)] = min(hypot(ribbon(r,1)-outlineCoords(:,1), ribbon(r,2)-outlineCoords(:,2)));
        end
        
        s = round(numel(pDist)/2);
        pDist1 = flip(pDist(1:s));
        pIdx1 = flip(pIdx(1:s));
        [~, pIdx_min1] = max(pDist1<1);
        
        pDist2 = pDist(s+1:end);
        pIdx2 = pIdx(s+1:end);
        [~, pIdx_min2] = max(pDist2<1);
        
        p1 = outlineCoords(pIdx1(pIdx_min1), :);
        p2 = outlineCoords(pIdx2(pIdx_min2), :);
        
        [l1_1, l2_1] = drawLine(p1(1), p1(2), medialAxisCoords(m, 1), medialAxisCoords(m, 2));
        [l1_2, l2_2] = drawLine(medialAxisCoords(m, 1), medialAxisCoords(m, 2), p2(1), p2(2));
        
        ribbons{c}{m, 1} = [l1_1, l1_2];
        ribbons{c}{m, 2} = [l2_1, l2_2];
        
        % Orient cells without stalk in such a way that wider end is
        % the cell pole
        orientationWidths(m) = hypot(p1(1)-p2(1), p1(2)-p2(2))*scaling;
        
        if debugging
            color = [rand rand rand];
            plot(h_ax, ribbon(:,2), ribbon(:,1), 'color', color);
            plot(h_ax, p1(1,2), p1(1,1), 'o', 'color', color, 'MarkerFaceColor', color)
            plot(h_ax, p2(1,2), p2(1,1), 'o', 'color', color, 'MarkerFaceColor', color)
            text(p1(1,2)+rand, p1(1,1)+rand, num2str(m), 'color', color, 'parent', h_ax)
            text(p2(1,2)+rand, p2(1,1)+rand, num2str(m), 'color', color, 'parent', h_ax)
            plot(h_ax, l2_1, l1_1, 'linewidth', 2, 'color', color)
            plot(h_ax, l2_2, l1_2, 'linewidth', 2, 'color', color)
        end
    end
    
    % Obtain cell length (length of medial axis)
    d = diff([medialAxisCoords(:, 1) medialAxisCoords(:, 2)]);
    cellLength{c} = sum(sqrt(sum(d.*d,2)));
    
    % Obtain cell width (longest ribbon)
    cellWidth{c} = max(orientationWidths);
    
    % Obtain the cells sinuosity
    cellSinuosity{c} = cellLength{c}/hypot(medialAxisCoords(1, 1)-medialAxisCoords(end, 1), medialAxisCoords(1, 2)-medialAxisCoords(end, 2));
    
    if ~cells.Stats(c).Stalk && orientationWidths(end-1) > orientationWidths(2) && ~cells.Stats(c).Bud
        % Flip medial axis of cell which has no stalk according to the
        % shape of the cell
        cells.Stats(c).CellMedialAxisIdx = flip(cells.Stats(c).CellMedialAxisIdx);
        cells.Stats(c).CellMedialAxisCoordinates = flip(cells.Stats(c).CellMedialAxisCoordinates);
        ribbons{c} = flip(ribbons{c});
    end
    
    if cells.Stats(c).Bud
        % Flip medial axis of bud
        cells.Stats(c).CellMedialAxisIdx = flip(cells.Stats(c).CellMedialAxisIdx);
        cells.Stats(c).CellMedialAxisCoordinates = flip(cells.Stats(c).CellMedialAxisCoordinates);
        ribbons{c} = flip(ribbons{c});
    end
end

[cells.Stats.CellLength] = cellLength{:};
[cells.Stats.CellWidth] = cellWidth{:};
[cells.Stats.CellSinuosity] = cellSinuosity{:};

% Set stalk length of cells with no stalk to zero
%stalkLength = {cells.Stats.StalkLength};
%noStalks = cellfun(@isempty, stalkLength);
%stalkLength(noStalks) = repmat({0}, 1, sum(noStalks));

%budLength = repmat({0}, 1, numel(cellLength));
%hasBud = cellfun(@(x) ~isempty(x), {cells.Stats.ConnectedWith});
%budLength(hasBud) = num2cell([cells.Stats.ConnectedWith]);

%cellStalkLength = cellfun(@(x, y) x+y, cellLength', stalkLength, 'UniformOutput', false);
%cellStalkBudLength = cellfun(@(x, y) x+y, cellStalkLength, stalkLength, 'UniformOutput', false);

%[cells.Stats.CellStalkLength] = cellStalkLength{:};
%[cells.Stats.CellStalkBudLength] = cellStalkBudLength{:};

% Remove minor axis length and recalculate cell length using the medial axis
cells.Stats = rmfield(cells.Stats, 'MinorAxisLength');

% Remove cells of small diameter which are no budding cells
minArea = pi*(minCellSize/2)^2;
Area = [cells.Stats.Area];

connectedWith = {cells.Stats.ConnectedWith};
toSmallCells = Area < minArea;
toSmallCells([cells.Stats.Bud]) = false;

% Delete buds of cells which are too small
toSmallCells([connectedWith{toSmallCells}]) = true;

cellDeleted = [cells.Stats.CellDeleted];
cellDeleted = num2cell(cellDeleted | toSmallCells | badMedialAxes);
[cells.Stats.CellDeleted] = cellDeleted{:};

% Adding comments
if sum(toSmallCells)
    comments = {cells.Stats.Comment};
    comments(toSmallCells) = cellfun(@(comment, minCellSize) sprintf('%sCell is too small (<%d px). ', comment, minCellSize), comments(toSmallCells), repmat({minCellSize}, 1, sum(toSmallCells)), 'UniformOutput', false);
    [cells.Stats.Comment] = comments{:};
end

% Convert area to microns
Area = num2cell(Area*scaling*scaling);
[cells.Stats.Area] = Area{:};

% Delete cells connetec to deleted cells
cellDeleted = [cells.Stats.CellDeleted];
connectedWith = [cells.Stats(cellDeleted).ConnectedWith];

if ~isempty(connectedWith)
    cellDeleted(connectedWith) = true;
    
    comments = {cells.Stats.Comment};
    comments(connectedWith) = cellfun(@(comments, cellID) sprintf('%sConnected to deleted cell #%d. ', comments, cellID), comments(connectedWith), num2cell(connectedWith), 'UniformOutput', false);
    [cells.Stats.Comment] = comments{:};
    
    cellDeleted = num2cell(cellDeleted);
    [cells.Stats.CellDeleted] = cellDeleted{:};
end


% Measure intensity properties
for ch = 1:numel(img)
    imSize = cells.ImageSize;
    
    medialAxisIntensity = cell(1, cells.NumObjects);
    medialAxisIntensity_max = cell(1, cells.NumObjects);
    stalkIntensity = cell(1, cells.NumObjects);
    meanCellIntensity = cell(1, cells.NumObjects);
    medianCellIntensity = cell(1, cells.NumObjects);
    minCellIntensity = cell(1, cells.NumObjects);
    maxCellIntensity = cell(1, cells.NumObjects);
    
    brightestFocus_A_Distance = cell(1, cells.NumObjects);
    brightestFocus_A_DistanceCenter = cell(1, cells.NumObjects);
    %brightestFocus_A_Idx = cell(1, cells.NumObjects);
    brightestFocus_A_Intensity = cell(1, cells.NumObjects);
    
    for c = 1:cells.NumObjects
        medialAxisCoords = cells.Stats(c).CellMedialAxisCoordinates;
        
        stalkIntensity{c} = img{ch}(cells.Stats(c).StalkIdx)';
        meanCellIntensity{c} = mean(img{ch}(cells.PixelIdxList{c}));
        medianCellIntensity{c} = median(img{ch}(cells.PixelIdxList{c}));
        minCellIntensity{c} = min(img{ch}(cells.PixelIdxList{c}));
        maxCellIntensity{c} = max(img{ch}(cells.PixelIdxList{c}));
        
        
        medialAxisIntensity{c} = zeros(1, numel(cells.Stats(c).CellMedialAxisIdx));
        medialAxisIntensity_max{c} = zeros(1, numel(cells.Stats(c).CellMedialAxisIdx));
        
        if expandMedialAxis % expand medial axis to cell outline
            for m = 1:size(medialAxisCoords,1)
                medialAxisIntensity{c}(m) = mean(img{ch}(unique(sub2ind(imSize, ribbons{c}{m, 1}, ribbons{c}{m, 2}))));
                medialAxisIntensity_max{c}(m) = max(img{ch}(unique(sub2ind(imSize, ribbons{c}{m, 1}, ribbons{c}{m, 2}))));
            end
            
        else
            medialAxisIntensity{c} = img{ch}(cells.Stats(c).CellMedialAxisIdx)';
        end
        
        % Calculate distance of first intensity maximum in cell to cell pole
        if expandMedialAxis
            [maxVal, dist] = max(medialAxisIntensity_max{c});
        else
            [maxVal, dist] = max(medialAxisIntensity{c});
        end
        %brightestFocus_A_Idx{c} = dist;
        brightestFocus_A_Intensity{c} = maxVal;
        
        distVec = [medialAxisCoords(:, 1) medialAxisCoords(:, 2)];
        
        if size(distVec, 1) == 1
            d = 0;
        else
            d = diff(distVec);
        end
        
        medialAxisContourLength = sqrt(sum(d.*d,2));
        brightestFocus_A_Distance{c} = sum(medialAxisContourLength(1:dist-1)) * scaling;
        
        % Obtain cell center
        midIdx = find(cumsum(medialAxisContourLength) >= sum(medialAxisContourLength)/2, 1);
        
        if midIdx < dist
            % Distance is negative
            brightestFocus_A_DistanceCenter{c} = sum(medialAxisContourLength(midIdx:dist-1)) * scaling;
        elseif midIdx > dist
            brightestFocus_A_DistanceCenter{c} = -sum(medialAxisContourLength(dist:midIdx-1)) * scaling;
        else
            brightestFocus_A_DistanceCenter{c} = 0;
        end
    end
    
    %Go along the whole structure (has to be outside the loop above,
    %because the intensity information of the bud is required)
    brightestFocus_B_Distance = cell(1, cells.NumObjects);
    brightestFocus_B_Intensity = cell(1, cells.NumObjects);
    %brightestFocus_B_Idx = cell(1, cells.NumObjects);
    
    
    for c = 1:cells.NumObjects
        % Collect additional intensity data
        cellStalkBudCoordinates = [cells.Stats(c).CellMedialAxisCoordinates; cells.Stats(c).StalkCoordinates; cells.Stats(cells.Stats(c).ConnectedWith).CellMedialAxisCoordinates];
        
        if expandMedialAxis
            if ~isempty(cells.Stats(c).ConnectedWith)
                budIntensity = medialAxisIntensity_max{cells.Stats(c).ConnectedWith};
            else
                budIntensity = [];
            end
            
            cellStalkBudIntensity = [medialAxisIntensity_max{c}, stalkIntensity{c}, budIntensity];
        else
            if ~isempty(cells.Stats(c).ConnectedWith)
                budIntensity = medialAxisIntensity{cells.Stats(c).ConnectedWith};
            else
                budIntensity = [];
            end
            
            cellStalkBudIntensity = [medialAxisIntensity{c}, stalkIntensity{c}, budIntensity];
        end
        
        % Calculate distance of first intensity maximum in cell-stalk-bud structure to mother cell pole
        [maxVal, dist] = max(cellStalkBudIntensity);
        
        %brightestFocus_B_Idx{c} = dist;
        brightestFocus_B_Intensity{c} = maxVal;
        
        distVec = [cellStalkBudCoordinates(1:dist, 1) cellStalkBudCoordinates(1:dist, 2)];
        if size(distVec, 1) == 1
            d = 0;
        else
            d = diff(distVec);
        end
        
        brightestFocus_B_Distance{c} = sum(sqrt(sum(d.*d,2))) * scaling;
    end
    
    if expandMedialAxis
        [cells.Stats.(['MedialAxisIntensity_max_', channelName{ch}])] = medialAxisIntensity_max{:};
    end
    
    [cells.Stats.(['MedialAxisIntensity', '_', channelName{ch}])] = medialAxisIntensity{:};
    [cells.Stats.(['StalkIntensity', '_', channelName{ch}])] = stalkIntensity{:};
    [cells.Stats.(['MeanCellIntensity', '_', channelName{ch}])] = meanCellIntensity{:};
    [cells.Stats.(['MedianCellIntensity', '_', channelName{ch}])] = medianCellIntensity{:};
    [cells.Stats.(['MinCellIntensity', '_', channelName{ch}])] = minCellIntensity{:};
    [cells.Stats.(['MaxCellIntensity', '_', channelName{ch}])] = maxCellIntensity{:};
    
    % Focus features
    [cells.Stats.(['BrightestFocus', '_', channelName{ch}, '_A_Distance'])] = brightestFocus_A_Distance{:};
    [cells.Stats.(['BrightestFocus', '_', channelName{ch}, '_B_Distance'])] = brightestFocus_B_Distance{:};
    [cells.Stats.(['BrightestFocus', '_', channelName{ch}, '_A_Intensity'])] = brightestFocus_A_Intensity{:};
    [cells.Stats.(['BrightestFocus', '_', channelName{ch}, '_B_Intensity'])] = brightestFocus_B_Intensity{:};
    
    [cells.Stats.(['BrightestFocus', '_', channelName{ch}, '_A_DistanceToCellCenter'])] = brightestFocus_A_DistanceCenter{:};
end

fprintf('[WORKER %d] Summary: %d cells (total), %d cells with stalks, %d cells with buds\n', worker, numel(cells.Stats), sum([cells.Stats.Stalk]), sum([cells.Stats.Bud]));


% Smooth line slighty
function [coordX, coordY] = smoothLine(coordX, coordY)
removeIdx = false(numel(coordX, 1));

for i = 1:numel(coordX)-2
   % Go along hypotenuse instead of triangle legs between two connected
   % pixels
   if hypot(coordX(i+2)-coordX(i), coordY(i+2)-coordY(i)) < 1.5
       removeIdx(i+1) = true;
   end
   
   % Go along hypotenuse instead of triangle legs between two pixels of
   % distance 2
   if hypot(coordX(i+2)-coordX(i), coordY(i+2)-coordY(i)) == 2
       coordX(i+1) = (coordX(i)+coordX(i+2))/2;
       coordY(i+1) = (coordY(i)+coordY(i+2))/2;
   end
end
coordX(removeIdx) = [];
coordY(removeIdx) = [];


% Checking tip of growing stalk for Intensity maxima
function [stalkIdx, goodStalk] = checkStalk(intValues, shell_idx, reference, stalkSensitivity)
meanVal = mean(reference);
stdVal = std(reference);

[maxVal, maxIdx] = max(intValues);

stalkIdx = shell_idx(maxIdx);

% Stalk growing criterion
if maxVal > (meanVal+stalkSensitivity*stdVal)
    goodStalk = 1;
else
    goodStalk = 0;
end


% Sort linear indices for line profiles
function sortedIdx = sortIdx(imSize, idx, startIdx)
idxOri = idx;
sortedIdx = zeros(numel(idx), 1);

sortedIdx(1) = startIdx;
idx(idx == startIdx) = NaN;

for i = 2:numel(sortedIdx)
    [NDidx, NDdist] = neighbourND(sortedIdx(i-1), imSize);
    [intersectPoints, NDidx_idx] = intersect(NDidx, idx);
    if ~isempty(intersectPoints)
        [~, minDist] = min(NDdist(NDidx_idx));
        
        sortedIdx(i) = intersectPoints(minDist(1));
        idx(idx == sortedIdx(i)) = NaN;
    else
        sortedIdx = sortedIdx(1:i-1);
        break;
    end
end


% Extend the medial cell axis to the tips
function [cellMedialAxis, cellOutlineIntersectionIdx] = propagateMedialAxis(imSize, cellMedialAxis, cell_outline, propagationLength, propagationDir)
[medialAxisCoordX, medialAxisCoordY] = ind2sub(imSize, cellMedialAxis);

switch propagationDir
    case 'stalk' % propagate medial axis to stalk side
        iter = 0;
        propDir = [1 1]*numel(cellMedialAxis)-[0 2];
    case 'tip' % propagate medial axis to tip side
        iter = 0;
        propDir = [1 3];
    case 'both' % propagate medial axis to both sides
        iter = [0 2];
        propDir = [1 3 [1 1]*numel(cellMedialAxis)-[0 2]];
end

if numel(cellMedialAxis) >= 3
    medialAxisCoordX = medialAxisCoordX(propDir(:));
    medialAxisCoordY = medialAxisCoordY(propDir(:));
    interpolateMedialAxis = true;
else
    interpolateMedialAxis = false;
end

for i = iter
    % propagate axis
    if interpolateMedialAxis
        dirVec = [medialAxisCoordX(2+i)-medialAxisCoordX(1+i), medialAxisCoordY(2+i)-medialAxisCoordY(1+i)];
        dirVec = -1*dirVec/norm(dirVec);
        propagation = [medialAxisCoordX(1+i)+propagationLength*dirVec(1) medialAxisCoordY(1+i)+propagationLength*dirVec(2)];
    else
        propagation = [medialAxisCoordX(1)+propagationLength*(i-1) medialAxisCoordY(1)]; % not fully debugged
    end
    [x_cell, y_cell] = ind2sub(imSize, cell_outline);
    
    dist = hypot(x_cell-propagation(1), y_cell-propagation(2));
    [~, minDistIdx] = min(dist);
    cellOutlineIntersectionIdx = cell_outline(minDistIdx);
    
    if interpolateMedialAxis
        [x_int, y_int] = drawLine(medialAxisCoordX(1+i), medialAxisCoordY(1+i), x_cell(minDistIdx), y_cell(minDistIdx));
        
        %dist = hypot(medialAxisCoordX(1+i)-x_cell(minDistIdx), medialAxisCoordY(1+i)-y_cell(minDistIdx));
        %x_int = round(linspace(medialAxisCoordX(1+i), x_cell(minDistIdx), ceil(1.42*dist)));
        %x_int = round(linspace(medialAxisCoordY(1+i), y_cell(minDistIdx), ceil(1.42*dist)));
    else
        [x_int, y_int] = drawLine(medialAxisCoordX(1), medialAxisCoordY(1), x_cell(minDistIdx), y_cell(minDistIdx));
        
        %dist = hypot(medialAxisCoordX(1)-x_cell(minDistIdx), medialAxisCoordY(1)-y_cell(minDistIdx));
        %x_int = round(linspace(medialAxisCoordX(1), x_cell(minDistIdx), ceil(1.42*dist)));
        %y_int = round(linspace(medialAxisCoordY(1), y_cell(minDistIdx), ceil(1.42*dist)));
    end
    
    cellMedialAxis = union(cellMedialAxis, sub2ind(imSize, x_int, y_int));
end

function [xn, yn] = drawLine(X0, Y0, X1, Y1)
n = 0:(1/round(sqrt((X1-X0)^2 + (Y1-Y0)^2 ))):1;
xn = round(X0 +(X1 - X0)*n);
yn = round(Y0 +(Y1 - Y0)*n);


%% 3rd party functions

%% Determine cell outline
function [nxy] = pixelOutline(binaryIM, sz1, sz2)
%binaryIM should be a binary image. This function walks counterclockwise
%around regions of ones and returns coordinates of pixel vertices suitable
%for plotting on top of an image to outline a region of interest.

if nargin == 1
    %treat binaryIM as a binaryIM
    bw = bwconncomp(binaryIM);
    [sz1, sz2] = size(binaryIM);
    
    
    bw = bw.PixelIdxList;
else
    %arguments 2 and 3 must be size(image,1) and size(image,2),
    %respectively
    bw = {binaryIM};
    binaryIM = zeros(sz1,sz2);
    binaryIM(bw{1}) = 1;
end

% Dilating cells
bw = cellfun(@(imSize, PixelIdxList) union(PixelIdxList, neighbourND(PixelIdxList, imSize)), repmat({[sz1, sz2]}, 1, numel(bw)), bw, 'UniformOutput', false);

nxy = cell(1,length(bw));

gix = [2 1 8;3 inf 7;4 5 6];
indwin = [-sz1-1, -1, sz1-1;-sz1 0 sz1; -sz1+1 +1 +sz1+1];
padwin = [nan 5 nan; 7 nan 3;nan 1 nan];
padwin1 = [nan 1 nan; 3 nan 7; nan 5 nan];
yr = {[.5 .5], [], [.5 -.5], [], [-.5 -.5], [], [-.5 .5], [], [.5 .5]};
xr = {[-.5 .5], [], [.5 .5], [], [.5 -.5], [], [-.5 -.5], [], [-.5 .5]};
for n = 1:length(bw)
    binaryIM = false(sz1,sz2);
    binaryIM(bw{n}) = true;
    binaryIM = imfill(binaryIM, 'holes');
    
    %ignore any unclosed pixelated polgons
    skip = false;
    for z = 1:length(bw{n})
        count1s = binaryIM(indwin + bw{n}(z));
        %sum(count1s(:)) == 1 for an isolated pixel, == 2 for a singly
        %connected pixel and ==3 for a doubly connected pixel....
        if sum(count1s(:)) < 3
            skip = true;
            break
        end
    end
    if skip, continue, end
    
    mask = binaryIM;
    
    ix = bw{n};
    r = (rem(ix-1,sz1)+1);
    c = (ceil(ix./sz1));
    
    %N
    eN = ix(r == 1);
    tmp = setdiff(ix, eN);
    N = ix(mask(tmp - 1) == 0);
    N = cat(1,N, eN);
    %W
    eW = ix(c == 1);
    tmp = setdiff(ix, eW);
    W = ix(mask(tmp - sz1) == 0);
    W = cat(1, W, eW);
    %S
    eS = ix(r == sz1);
    tmp = setdiff(ix,eS);
    S = ix(mask(tmp + 1) == 0);
    S = cat(1,S, eS);
    %E
    eE = ix(c == sz2);
    tmp = setdiff(ix,eE);
    E = ix(mask(tmp + sz1) == 0);
    E = cat(1,E,eE);
    
    ed = cat(1,N,W,S,E);
    mask = false(sz1,sz2);
    mask(ed) = 1;
    
    nx = []; ny = [];
    fi = max(ed);
    ordered = [];
    while ~isempty(ed)
        %matrix of pixel locations
        ordered(end+1) = fi;
        pxmat = indwin + fi;
        
        win = mask(pxmat);
        if sum(win(:)) == 0
            nx = [];
            ny = [];
            break
        end
        
        tmp = win.*gix;
        tmp(tmp == 0) = inf;
        mask(fi) = 0;
        [~, filoc] = min(tmp(:));
        y = (rem(fi-1,sz1)+1);
        x = (ceil(fi./sz1));
        
        im2win = ~binaryIM(pxmat).*padwin;
        im2win(im2win == 0) = nan;
        if any(diff(sort(im2win(~isnan(im2win)))) - 2)
            im2win1 = ~binaryIM(pxmat).*padwin1;
            im2win1(im2win1 == 0) = nan;
            [~,io] = sort(im2win1(:));
            edgeind = im2win(io);
        else
            edgeind = sort(im2win(:));
        end
        
        edgeind(isnan(edgeind)) = [];
        vL = length(edgeind);
        nx(end+1) = x;
        ny(end+1) =  y;
        ed(ed==fi) = [];
        fi = pxmat(filoc);
    end
    
    nxy{n} = [ny' nx'];
    if length(nx) < 5, continue, end
    nxy{n}(end+1,1:2) = nxy{n}(1,:);
    
end
nxy(cellfun(@isempty, nxy)) = [];


%% Band-pass filtering
function res = bpass(image_array,lnoise,lobject,threshold)
%
% NAME:
%               bpass
% PURPOSE:
%               Implements a real-space bandpass filter that suppresses
%               pixel noise and long-wavelength image variations while
%               retaining information of a characteristic size.
%
% CATEGORY:
%               Image Processing
% CALLING SEQUENCE:
%               res = bpass( image_array, lnoise, lobject )
% INPUTS:
%               image:  The two-dimensional array to be filtered.
%               lnoise: Characteristic lengthscale of noise in pixels.
%                       Additive noise averaged over this length should
%                       vanish. May assume any positive floating value.
%                       May be set to 0 or false, in which case only the
%                       highpass "background subtraction" operation is
%                       performed.
%               lobject: (optional) Integer length in pixels somewhat
%                       larger than a typical object. Can also be set to
%                       0 or false, in which case only the lowpass
%                       "blurring" operation defined by lnoise is done,
%                       without the background subtraction defined by
%                       lobject.  Defaults to false.
%               threshold: (optional) By default, after the convolution,
%                       any negative pixels are reset to 0.  Threshold
%                       changes the threshhold for setting pixels to
%                       0.  Positive values may be useful for removing
%                       stray noise or small particles.  Alternatively, can
%                       be set to -Inf so that no threshholding is
%                       performed at all.
%
% OUTPUTS:
%               res:    filtered image.
% PROCEDURE:
%               simple convolution yields spatial bandpass filtering.
% NOTES:
% Performs a bandpass by convolving with an appropriate kernel.  You can
% think of this as a two part process.  First, a lowpassed image is
% produced by convolving the original with a gaussian.  Next, a second
% lowpassed image is produced by convolving the original with a boxcar
% function. By subtracting the boxcar version from the gaussian version, we
% are using the boxcar version to perform a highpass.
%
% original - lowpassed version of original => highpassed version of the
% original
%
% Performing a lowpass and a highpass results in a bandpassed image.
%
% Converts input to double.  Be advised that commands like 'image' display
% double precision arrays differently from UINT8 arrays.

% MODIFICATION HISTORY:
%               Written by David G. Grier, The University of Chicago, 2/93.
%
%               Greatly revised version DGG 5/95.
%
%               Added /field keyword JCC 12/95.
%
%               Memory optimizations and fixed normalization, DGG 8/99.
%               Converted to Matlab by D.Blair 4/2004-ish
%
%               Fixed some bugs with conv2 to make sure the edges are
%               removed D.B. 6/05
%
%               Removed inadvertent image shift ERD 6/05
%
%               Added threshold to output.  Now sets all pixels with
%               negative values equal to zero.  Gets rid of ringing which
%               was destroying sub-pixel accuracy, unless window size in
%               cntrd was picked perfectly.  Now centrd gets sub-pixel
%               accuracy much more robustly ERD 8/24/05
%
%               Refactored for clarity and converted all convolutions to
%               use column vector kernels for speed.  Running on my
%               macbook, the old version took ~1.3 seconds to do
%               bpass(image_array,1,19) on a 1024 x 1024 image; this
%               version takes roughly half that. JWM 6/07
%
%       This code 'bpass.pro' is copyright 1997, John C. Crocker and
%       David G. Grier.  It should be considered 'freeware'- and may be
%       distributed freely in its original form when properly attributed.

if nargin < 3, lobject = false; end
if nargin < 4, threshold = 0; end

normalize = @(x) x/sum(x);

image_array = double(image_array);

if lnoise == 0
    gaussian_kernel = 1;
else
    gaussian_kernel = normalize(...
        exp(-((-ceil(5*lnoise):ceil(5*lnoise))/(2*lnoise)).^2));
end

if lobject
    boxcar_kernel = normalize(...
        ones(1,length(-round(lobject):round(lobject))));
end

% JWM: Do a 2D convolution with the kernels in two steps each.  It is
% possible to do the convolution in only one step per kernel with
%
% gconv = conv2(gaussian_kernel',gaussian_kernel,image_array,'same');
% bconv = conv2(boxcar_kernel', boxcar_kernel,image_array,'same');
%
% but for some reason, this is slow.  The whole operation could be reduced
% to a single step using the associative and distributive properties of
% convolution:
%
% filtered = conv2(image_array,...
%   gaussian_kernel'*gaussian_kernel - boxcar_kernel'*boxcar_kernel,...
%   'same');
%
% But this is also comparatively slow (though inexplicably faster than the
% above).  It turns out that convolving with a column vector is faster than
% convolving with a row vector, so instead of transposing the kernel, the
% image is transposed twice.

gconv = conv2(image_array',gaussian_kernel','same');
gconv = conv2(gconv',gaussian_kernel','same');

if lobject
    bconv = conv2(image_array',boxcar_kernel','same');
    bconv = conv2(bconv',boxcar_kernel','same');
    
    filtered = gconv - bconv;
else
    filtered = gconv;
end

% Zero out the values on the edges to signal that they're not useful.
lzero = max(lobject,ceil(5*lnoise));

filtered(1:(round(lzero)),:) = 0;
filtered((end - lzero + 1):end,:) = 0;
filtered(:,1:(round(lzero))) = 0;
filtered(:,(end - lzero + 1):end) = 0;

% JWM: I question the value of zeroing out negative pixels.  It's a
% nonlinear operation which could potentially mess up our expectations
% about statistics.  Is there data on 'Now centroid gets subpixel accuracy
% much more robustly'?  To choose which approach to take, uncomment one of
% the following two lines.
% ERD: The negative values shift the peak if the center of the cntrd mask
% is not centered on the particle.

% res = filtered;
filtered(filtered < threshold) = 0;
res = filtered;

function [Iadj , Radj, Nfound ] = neighbourND( index, sizeA, res )
% function  [Iadj , Radj, Nfound] = neighbour3D( index,  sizeA, res )
% Calculate the linear indices for neighboring points in a matrix
% Second output is and array of distances based on an input resolution vector
% This resolution vector defaults to ones(1,ndims)
% The output Nfound reports the number of neighbours found in within the
% matrix. For 2D we expect up to 8, for 3D up to 26 etc...
%
% Example 1:
% A is a 128x128x16 image data matrix with a spatial resolution of
% 0.1x 0.25x .375 mm^3
% to get the neighbouring point linear indices for point 456 we do
% sizeA = [128 128 16]
% [ Iadj , Radj, Nfound] = neighbourND( 456, sizeA, [ .10 .25 .375] )
%
% NEW: now index can be a column array with linear indices
% Output Iadj will be Nx8 (2D) or Nx26 (3D) etc and Radj will be
% a row array 1x8 or 1x26 etc...
%
% Example 2:
% create points near the center of a 144x192x16 matrix
% spatial resolution .3 x .3x 5 mm^3
% idx = (-6:1:6)+((144*192*3)+144*96+76)
%[ Iadj , Radj, Nfound] = neighbourND( idx , [144,192, 32] , [.3, 0.3, 5])
% Results in 11x26 matrix Iadj,
% 26 distances in Radj and Nfound is 26
%
% The neighbour indices outside the matrix will be zero!
% when a single index is entered the outside points are still removed so a
% point in a 3D matrix at the edge can sill return 17 neighbours or even less
% when it is a corner.
%==============================================

%==============================================
% Ronald Ouwerkerk 2010 NIH/NIDDK
% New version: Now handles arrays of indices
% This script is made available on Matlab file exchange by the author
% for use by other Matlab programmers.
% This script is not intended for commercial use.
% If used for published work a reference or acknowledgement is greatly
% appreciated.
% The function was tested for several 1D(col and row), 2D, 3D and 4D cases
% I cannot be sure that it really works for all dimensionalities.
% Let me know if you find a bug (and feel free to squash it for me)
%==============================================

%% Set defaults and process input parameters
% Get dimensionality
ndimA = length( sizeA );

%Set default resolution to isotropic distances
if nargin < 3
    res =ones(1, length( sizeA) );
else
    if length(res) < ndimA;
        errstr = sprintf('\nError in %s.\n The length of the resolution array (%d) must equal the number of matrix dimensions (%d)\n', ...
            mfilename, length(res), ndimA);
        disp(errstr)
        help( mfilename)
        return
    else
        % reduce the resolution array, last digit is probably slice
        % thickness, irrelevant if we have one slice only
        res = res( 1:ndimA );
    end
end

%% explicit version of ind2sub
% ind2sub requires multiple output arguments, one for each dimension
ilin = index(:);
np = length( ilin );
imat = ones( np, ndimA);

for di = ndimA:-1:2
    blocksize = prod( sizeA( 1:(di-1)  ) );
    ndi = 1+ floor( ( ilin-1) / blocksize );
    ilin = ilin- (ndi -1) *blocksize;
    imat(:,di) = ndi;
end
imat(:,1) = ilin;

%% Find the indices of neighbours
% Get all the index permutations for neighbours ( -1, +1) over all
% dimensions. The total number of neighbours should be three  to the power Ndim
% minus one if we discard the original point itself

% initialize the shift index array
nneighb = 3^ndimA;
nbi = zeros( nneighb, ndimA);

di = ndimA;
while ( di )
    N = 3^(di-1);
    ni = 1:N;
    while( ni(end) < nneighb+1 )
        for val=[-1, 0, 1]
            nbi( ni ,di ) = val;
            ni = ni+ N;
        end
    end
    di = di-1;
end

%% Create distance matrix
d = ones(nneighb, 1) * res;
d = d.*abs( nbi );
% create a row vector with distances
dvec = sqrt( sum( d.^2, 2))';
% Get index to exclude the original point: distance = 0
notorig = logical( dvec > 0 );

%% Add the input index array to nbi to get all neighbours
% set up the array for neighbour indices
nd = length( index);
Iadj = zeros( nd, nneighb );
kdo = notorig(ones(nd,1), : );

for di = 1:ndimA
    indices = imat( :, di );
    shifts = nbi( :, di )';
    neighbindices = indices( :, ones( 1,nneighb)) +shifts( ones(nd, 1), : ) ;
    maxmat = sizeA( di );
    % set up mask matrix to keep indices within limits and excllude the original point
    s = logical( neighbindices <= maxmat );
    s =logical( neighbindices > 0 ) & s;
    kdo = kdo & s;
    % Calculate the linear index
    if di == 1
        Iadj( kdo ) =  neighbindices( kdo );
    else
        blocksize = prod( sizeA( 1:(di-1)  ) );
        m = neighbindices-1;
        Iadj(kdo )  = Iadj(kdo )+ m(kdo)*blocksize;
    end
end

%% Select only the sensible points for the neighbour index and distances matrices
% Remove columns that have no valid indices anywhere at all (e.g. origin)
% for shorter index lists with  all points near the edges more may be
% removed.
if nd == 1
    allkdo = any( kdo, 1);
    Iadj = Iadj( :, allkdo);
    Radj = dvec( allkdo );
    Nfound = length(  find( allkdo ) );
else
    Nfound = nneighb-1;
    Radj = dvec;
    iself = (Radj == 0);
    Iadj = Iadj(:,~iself);
    Radj = Radj(~iself);
end

%END



