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

function dataGUI = trackingAlgorithm(dataGUI, params, range, minTrackID)
frames = dataGUI.frames;

data = [];

% Check if paralelle processing is enabled
doParallel_h = findobj(dataGUI.mainFigure, 'Tag', 'ParallelProcessing');
if doParallel_h.Value
    myCluster = parcluster('local');
    nWorkers = myCluster.NumWorkers;
else
    nWorkers = 0;
end

guiPath = dataGUI.guiPath;

trackMethod = 1;

for f_idx = 1:numel(range)%length(files)
    f = range(f_idx);
    if ~iscancelled(guiPath)
        if f_idx == 1
            data{2}.objects = frames(f).cells;
            objects2 = data{2}.objects;
            try
                objects2 = rmfield(objects2, 'Parents');
            end
            try
                objects2 = rmfield(objects2, 'Grandparents');
            end
            disp(' - reference frame');
        end
        
        if f_idx > 1
            
            data{1} = data{2};
            data{2}.objects = frames(f).cells;
            PixelIdxList1_exp = PixelIdxList2_exp;
            
            % Look for objects in data{2} and compare with Parents in data{1}
            objects1 = data{1}.objects;
            try
                objects1 = rmfield(objects1, 'Parents');
            end
            try
                objects1 = rmfield(objects1, 'Grandparent');
            end
            objects2 = data{2}.objects;
            try
                objects2 = rmfield(objects2, 'Parents');
            end
            try
                objects2 = rmfield(objects2, 'Grandparent');
            end
            
            disp([' - children: ', num2str(objects2.NumObjects), ', Parents: ', num2str(objects1.NumObjects)]);
            
            PixelIdxList1 = objects1.PixelIdxList;
            PixelIdxList2 = objects2.PixelIdxList;
            
            % Enlarge objects
            fprintf(' - calculating overlap');
            
            coords1 = [objects1.Stats.Centroid];
            coords2 = {objects2.Stats.Centroid};
            coords2_array = [objects2.Stats.Centroid];
            
            imageSize = objects2.ImageSize;
            
            nObj1 = objects1.NumObjects;
            nObj2 = objects2.NumObjects;
            TrackID1 = [objects1.Stats.TrackID];
            TrackID2 = zeros(nObj2,1);
            Parent = zeros(nObj2,1);
            Grandparent = zeros(nObj2,1);
            
            overlap3D = @(a,b) sum(ismember(a,b));
            
            PixelIdxList2_exp = cell(size(PixelIdxList2));
            probablyNewCell = false(1, nObj2);
            %        try
            %parfor (obj2ID = 1:nObj2, nWorkers)
            for obj2ID = 1:nObj2
                % Expand the current cell (the other cells are already expanded
                if params.trackCellsDilatePx > 0
                    shell = setxor(neighbourND(PixelIdxList2{obj2ID}, imageSize), PixelIdxList2{obj2ID});
                    
                    for i = 2:params.trackCellsDilatePx-1
                        if params.trackCellsDilatePx > 1
                            shell = union(neighbourND(shell, imageSize), shell);
                        end
                    end
                    PixelIdxList2_exp{obj2ID} = union(shell, PixelIdxList2{obj2ID});
                else
                    PixelIdxList2_exp{obj2ID} = PixelIdxList2{obj2ID};
                end
                
                % Determine nearby cells
                coordsOfActualCell = coords2{obj2ID};
                
                x = coords1(1:2:end);
                y = coords1(2:2:end);
                
                dist = hypot(coordsOfActualCell(1)-x, coordsOfActualCell(2)-y);
                
                cellsCloseBy = find(dist<params.searchRadius);
                
                if ~isempty(cellsCloseBy)
                    % Determine overlap
                    overlappingObjects = [cellfun(overlap3D, PixelIdxList1_exp(cellsCloseBy), ...
                        repmat(PixelIdxList2_exp(obj2ID),size(PixelIdxList1_exp(cellsCloseBy))))' cellsCloseBy'];
                    
                    
                    [~, index] = sort(overlappingObjects(:,1), 'descend'); % sort for overlap
                    
                    overlappingObjects = overlappingObjects(index,:);
                    
                    if overlappingObjects(1,1) > 0
                        %disp(['       - alpha = ', num2str(overlappingObjects(1,3))]);
                        Parent(obj2ID) = overlappingObjects(1,2);
                        TrackID2(obj2ID) = TrackID1(Parent(obj2ID));
                    else
                        % No cell close by
                        % note objID for further processing
                        probablyNewCell(obj2ID) = 1;
                        
                        % No overlap with closeby cell
                        %Parent(obj2ID) = 0;
                        %TrackIDMaxLastFrame = max(TrackID1)+1;
                        %TrackID2(obj2ID) = TrackIDMaxLastFrame;%maxTrackID;
                    end
                else
                    % No cell close by
                    % note objID for further processing
                    probablyNewCell(obj2ID) = 1;
                    
                    %Parent(obj2ID) = 0;
                    %TrackIDMaxLastFrame = max(TrackID1)+1;
                    %TrackID2(obj2ID) = TrackIDMaxLastFrame;%maxTrackID;
                end
            end
            %         catch err
            %             warning(err.message);
            %         end
            
            
            %% Process cells which have no cells close by in previous frame
            % Almost same procedure than used to determine the Parent cells
            % but now all calculattions are based on the current frame
            obj2ID_noNeighbors = find(probablyNewCell);
            reLinkCounter = 0;
            if ~isempty(obj2ID_noNeighbors)
                newCell = false(1, nObj2);
                
                fprintf(' - treating cells with no Parents');
                for obj2ID = obj2ID_noNeighbors
                    % check wether cell is physically connected to other structure
                    
                    % Determine nearby cells
                    coordsOfActualCell = coords2{obj2ID};
                    
                    x = coords2_array(1:2:end);
                    y = coords2_array(2:2:end);
                    
                    dist = hypot(coordsOfActualCell(1)-x, coordsOfActualCell(2)-y);
                    
                    cellsCloseBy = find(dist<params.searchRadius);
                    % remove the object with ID obj2ID
                    cellsCloseBy(cellsCloseBy == obj2ID) = [];
                    
                    shell = setxor(neighbourND(PixelIdxList2{obj2ID}, imageSize), PixelIdxList2{obj2ID});
                    
                    % Check wether any nearby cell is overlapping with shell
                    if ~isempty(cellsCloseBy)
                        
                        % Determine overlap
                        overlappingObjects = [cellfun(overlap3D, PixelIdxList2(cellsCloseBy), ...
                            repmat({shell},size(PixelIdxList2(cellsCloseBy))))' cellsCloseBy'];
                        
                        [~, index] = sort(overlappingObjects(:,1), 'descend'); % sort for overlap
                        
                        overlappingObjects = overlappingObjects(index,:);
                        
                        if overlappingObjects(1,1) > 0
                            % Check wether the touching object has already a TrackID
                            if ~TrackID2(overlappingObjects(1,2))
                                maxTrackID = maxTrackID + 1;
                                TrackID2(overlappingObjects(1,2)) = maxTrackID;
                                TrackID2(obj2ID) = maxTrackID;
                            else
                                TrackID2(obj2ID) = TrackID2(overlappingObjects(1,2));
                            end
                            reLinkCounter = reLinkCounter + 1;
                            Parent(obj2ID) = Parent(overlappingObjects(1,2));
                        else
                            % No overlap with closeby cell
                            newCell(obj2ID) = 1;
                        end
                    else
                        % No cell close by
                        newCell(obj2ID) = 1;
                    end
                end
                
                % Now deal with the new appearing cells which are not linked to
                % other ones
                obj2ID_noNeighbors = find(newCell);
                if ~isempty(obj2ID_noNeighbors)
                    for obj2ID = obj2ID_noNeighbors
                        if f_idx > 2
                            assignNewTrackID = 0;
                            % First check wether the cell was already there some frames
                            % before by analyzing the Grandparents
                            
                            coordsOfActualCell = coords2{obj2ID};
                            coords3 = [data{3}.objects.Stats.Centroid];
  
                            x = coords3(1:2:end);
                            y = coords3(2:2:end);
                            
                            dist = hypot(coordsOfActualCell(1)-x, coordsOfActualCell(2)-y);
                            
                            cellsCloseBy = find(dist<params.searchRadius);
                            
                            if ~isempty(cellsCloseBy)
                                % Determine overlap
                                overlappingObjects = [cellfun(overlap3D, data{3}.objects.PixelIdxList(cellsCloseBy), ...
                                    repmat(PixelIdxList2(obj2ID),size(data{3}.objects.PixelIdxList(cellsCloseBy))))' cellsCloseBy'];
                                
                                [~, index] = sort(overlappingObjects(:,1), 'descend'); % sort for overlap*angle
                                
                                if overlappingObjects(index(1),1) > 0.5*numel(data{3}.objects.PixelIdxList{cellsCloseBy(index(1))}) && ...
                                        overlappingObjects(index(1),1)  > 0.5*numel(PixelIdxList2{obj2ID})
                                    
                                    % If overlap is more the 50% than do the linkage
                                    reLinkCounter = reLinkCounter + 1;
                                    Parent(obj2ID) = NaN;
                                    Grandparent(obj2ID) = cellsCloseBy(index(1));
                                    TrackID2(obj2ID) = data{3}.objects.Stats(cellsCloseBy(index(1))).TrackID;
                                else
                                    assignNewTrackID = 1;
                                end
                                
                            else
                                assignNewTrackID = 1;
                            end
                        else
                            assignNewTrackID = 1;
                        end
                        
                        if assignNewTrackID
                            Parent(obj2ID) = 0;
                            maxTrackID = maxTrackID + 1;
                            TrackID2(obj2ID) = maxTrackID;
                        end
                        
                    end
                end
            end
            
            fprintf('   - relations: %d, new cells: %d, re-linked cells: %d, max TrackID: %d\n', sum(Parent>0), sum(Parent==0), reLinkCounter, maxTrackID);
            
            Parent = num2cell(Parent);
            [objects2.Stats.Parent] = Parent{:};
            
            Grandparent = num2cell(Grandparent);
            [objects2.Stats.Grandparent] = Grandparent{:};
            
            objects2.maxTrackID = maxTrackID;
            % New tracks
            NNewTracks = length(TrackID2(TrackID2 == max(TrackID1)+1));
            TrackID2(TrackID2 == max(TrackID1)+1) = max(TrackID1)+1:max(TrackID1)+NNewTracks;
            
            TrackID2 = num2cell(TrackID2);
            [objects2.Stats.TrackID] = TrackID2{:};
            
            data{3} = data{1};
            data{1}.objects = objects1;
            data{2}.objects = objects2;
            
            
        else
            PixelIdxList2 = objects2.PixelIdxList;
            imageSize = objects2.ImageSize;
            PixelIdxList2_exp = cell(size(PixelIdxList2));
            
            Parents = num2cell(zeros(objects2.NumObjects,1));%num2cell(1:objects2.NumObjects);
            Grandparents = num2cell(zeros(objects2.NumObjects,1));
            TrackIDs = num2cell(minTrackID+[1:double(objects2.NumObjects)]);
            
            [objects2.Stats.Parent] = Parents{:};
            [objects2.Stats.Grandparent] = Grandparents{:};
            
            switch trackMethod
                case 1
                    [objects2.Stats.TrackID] = TrackIDs{:};
                case 2
                    startTrackID = num2cell(ones(size(Parents)));
                    [objects2.Stats.TrackID] = startTrackID{:};
            end
            
            maxTrackID = max([objects2.Stats.TrackID]);
            objects2.maxTrackID = maxTrackID;
            
            % Enlarging Volume
            %parfor (obj2ID = 1:objects2.NumObjects,nWorkers)
             for obj2ID = 1:objects2.NumObjects
                if params.trackCellsDilatePx > 0
                    shell = setxor(neighbourND(PixelIdxList2{obj2ID}, imageSize), PixelIdxList2{obj2ID});
                    
                    for i = 2:params.trackCellsDilatePx-1
                        if params.trackCellsDilatePx > 1
                            shell = union(neighbourND(shell, imageSize), shell);
                        end
                    end
                    PixelIdxList2_exp{obj2ID} = union(shell, PixelIdxList2{obj2ID});
                else
                    PixelIdxList2_exp{obj2ID} = PixelIdxList2{obj2ID};
                end
            end
        end
        objects = objects2;
        data{2}.objects = objects;
        
        frames(f).cells = objects;
        updateWaitbar(dataGUI.axes.progress, f/numel(dataGUI.frames))
    end
end

dataGUI.frames = frames;