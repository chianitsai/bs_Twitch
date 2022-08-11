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

function showTracks(src, ~)
data = getUIData(src);

tracks_h = findobj(data.axes.main, '-regexp', 'Tag', 'track');
if ~isempty(tracks_h)
    delete(tracks_h);
    src.String = 'Show tracks';
    return;
end

lineWidth_h = findobj(data.mainFigure, 'tag', 'LineWidth');
lineWidth = str2double(lineWidth_h.String);
trajectory_color_h = findobj(data.mainFigure, 'tag', 'TrajectoryColor');
trajectory_color = trajectory_color_h.UserData;
            
src.String = 'Hide tracks';

if isfield(data.frames(1).cells.Stats, 'TrackID')
    allTracks  = [];
    stats = cell(numel(data.frames), 1);
    
    for k = 1:numel(data.frames)
        try
            stats{k} = data.frames(k).cells.Stats;
            trackIDs = [stats{k}.TrackID];
            trackIDs([stats{k}.Bud]) = [];
            
            allTracks = [allTracks, trackIDs];
        catch
            src.String = 'Show tracks';
        end
    end
    
    for t = 1:numel(allTracks)
        coordsTrack = [];
        trackID = allTracks(t);
        
        for k = 1:numel(data.frames)
            try
                idx = find([stats{k}.TrackID] == trackID);
                if ~isempty(idx)
                    coords = stats{k}(idx).Centroid;
                    coordsTrack = [coordsTrack; coords];
                end
            catch
                src.String = 'Show tracks';
            end
        end
        
        if ~isempty(coordsTrack)
            plot(data.axes.main, coordsTrack(:,1), coordsTrack(:,2), 'color', trajectory_color, 'Tag', 'track', 'LineWidth', lineWidth)
            
        end
    end
else
    src.String = 'Show tracks';
    msgbox('Cells are not tracked.', 'Warning', 'help', 'modal')
end


