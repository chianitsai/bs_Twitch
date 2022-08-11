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

function clickTrackTable(src, eventdata, mode, trackID)

h = gcf;
data = getUIData(h);

toggleBusyPointer(data, 1)

if nargin == 3
    indices = src.SelectedRows;
    % Look for beginning of track
    try
        trackID = src.getModel.getValueAt(indices(1),0);
        if ischar(trackID)
            trackID = str2num(trackID);
        end
    catch
        return;
    end
end

% Find out which frames are containing the desired TrackID
trackIDs = cellfun(@(x) [x.Stats.TrackID], {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells}, 'UniformOutput', false);
cellIDs = cellfun(@(x, y) find(x==y), trackIDs, repmat({trackID}, 1, numel(trackIDs)), 'UniformOutput', false);

% Check for division
daughterCells = cellfun(@numel, cellIDs);
divisionEvent = find(daughterCells>1);
if ~isempty(divisionEvent)
    msgbox(sprintf('Division event found in frame %d.', divisionEvent(1)), 'Please note', 'help', 'modal');
    
    
    nonEmptyFrames = cellfun(@(x) ~isempty(x), cellIDs);
    cellIDs2 = cellfun(@(x) x(1), cellIDs(nonEmptyFrames), 'UniformOutput', false);
    cellIDs = cell(1, numel(cellIDs));
    
    cellIDs(nonEmptyFrames) = cellIDs2;
end



%framesWithTrackIDPresent = find(cellfun(@(x) ~isempty(x), cellIDs));
cellDeleted = cellfun(@(x, y) [x.Stats(y).CellDeleted], {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells}, cellIDs, 'UniformOutput', false);
cellDeleted2 = find(cellfun(@(x) ~isempty(x), cellDeleted));
framesWithTrackIDPresent = cellDeleted2(find(cellfun(@(x) x == 0, cellDeleted(cellDeleted2))));

if isempty(framesWithTrackIDPresent)
    msgbox('All cells associated with this track were deleted manually.', 'Please note', 'warn', 'modal');
    toggleBusyPointer(data, 0)
    return
end

startFrame = framesWithTrackIDPresent(1);
endFrame = framesWithTrackIDPresent(end);

if numel(framesWithTrackIDPresent) ~= numel(cellDeleted2)
    msgbox(sprintf('In %d out of %d frames of this track (ID: %d) the cell was marked as "deleted". Now the latest valid frame will be shown (t = %d).',...
        numel(cellDeleted2) - numel(framesWithTrackIDPresent), numel(cellDeleted2), trackID, endFrame), 'Please note', 'help', 'modal');
end

switch mode
    case 'analysisTab'
        if size(indices, 1) == 1
            kymograph_trackID_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackID');
            kymograph_trackID_h.String = num2str(trackID);
            
            kymograph_trackStart_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackStart');
            kymograph_trackStart_h.String = num2str(startFrame);
            
            kymograph_trackEnd_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackEnd');
            kymograph_trackEnd_h.String = num2str(endFrame);
        end
        
        toggleBusyPointer(data, 0)
        
    case 'segmentationTab'
        if size(indices, 1) == 1
            zoom(data.axes.main, 'off')
            pan(data.axes.main, 'off')
            datacursormode(data.mainFigure, 'off')
            
            try
                % Delete the draggable ROI
                delete(data.ui.ROI_rect);
            end
            
            lineWidth_h = findobj(data.mainFigure, 'tag', 'LineWidth');
            lineWidth = str2double(lineWidth_h.String);
            trajectory_color_h = findobj(data.mainFigure, 'tag', 'TrajectoryColor');
            trajectory_color = trajectory_color_h.UserData;
            
            
            ax_h_progress = data.axes.progress;
            displayStatus(h, [], sprintf('Plotting track %d', trackID))
            updateWaitbar(ax_h_progress, 0.3)
            
            displayImage(h, [], endFrame)
            
            updateWaitbar(ax_h_progress, 0.7)
            % Zoom on cell
            coords = [data.frames(endFrame).cells.Stats(cellIDs{endFrame}).Centroid];
            x = coords(1:2:end);
            y = coords(2:2:end);
            
            CellSize_h = findobj(data.mainFigure, 'Tag', 'CellSize');
            CellSize = 5*str2num(CellSize_h.String);
            
            xLimits = [min(x) - CellSize, max(x) + CellSize];
            yLimits = [min(y) - CellSize, max(y) + CellSize];
            
            data.axes.main.XLim = xLimits;
            data.axes.main.YLim = yLimits;
            
            % Plot track
            coordsTrack = [];
            
            frameIdx = startFrame:endFrame;
            
            trackIDs = cellfun(@(x) [x.Stats.TrackID], {data.frames(frameIdx).cells}, 'UniformOutput', false);
            
            cellIDs = cellfun(@(x, y) find(x==y), trackIDs, repmat({trackID}, 1, numel(trackIDs)), 'UniformOutput', false);
            
            frameIdx(cellfun(@isempty, cellIDs)) = [];
            cellIDs(cellfun(@isempty, cellIDs)) = [];
            
            coordinates = cellfun(@(x, y) x.Stats(y).Centroid, {data.frames(frameIdx).cells}, cellIDs, 'UniformOutput', false);
            
            coordinates = [coordinates{:}];
            
            coordsTrack = [coordinates(1:2:end)' coordinates(2:2:end)'];
            
            updateWaitbar(ax_h_progress, 0.9)
            
            tracks_h = findobj(data.axes.main, '-regexp', 'Tag', 'track');
            delete(tracks_h);
            
            if ~isempty(coordsTrack)
                plot(data.axes.main, coordsTrack(:,1), coordsTrack(:,2), 'color', trajectory_color, 'Tag', 'track', 'LineWidth', lineWidth)
            end
            
            
            pb_showTracks_h = findobj(data.mainFigure, 'Tag', 'pb_showTracks');
            pb_showTracks_h.String = 'Hide tracks';
            
            updateWaitbar(data.axes.progress, 1)
            displayStatus(h, [], '')
        end
end