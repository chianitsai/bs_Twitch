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

function updateTrackTables(data)

trackIDsAll = cellfun(@(x) [x.Stats.TrackID], {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells}, 'UniformOutput', false);
buds = cellfun(@(x) [x.Stats.Bud], {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells}, 'UniformOutput', false);
cellDeleted = cellfun(@(x) [x.Stats.CellDeleted], {data.frames(cellfun(@(x) ~isempty(x), {data.frames.cells})).cells}, 'UniformOutput', false);

trackIDs = [trackIDsAll{:}];
buds = [buds{:}];
cellDeleted = [cellDeleted{:}];
trackIDs(buds | cellDeleted) = [];

trackIDsUnique = unique(trackIDs)';

duration = zeros(numel(trackIDsUnique), 1);
for trackID = 1:numel(trackIDsUnique)
    duration(trackID) = sum(cellfun(@(x) ~isempty(x), arrayfun(@(x, y) find(x==y), trackIDs, repmat(trackIDsUnique(trackID), 1, numel(trackIDs)), 'UniformOutput', false)));
end

% In Analysis tab
createJavaTable(data.tables.tableSelectedTrack{2}, [], data.tables.tableSelectedTrack{1}, num2cell([trackIDsUnique, duration]), {'Track ID', 'Track length (frames)'}, [false false], true);

% In Cell/Stalk detection
createJavaTable(data.tables.tableTracksSegmentation{2}, [], data.tables.tableTracksSegmentation{1}, num2cell([trackIDsUnique, duration]), {'Track ID', 'Track length (frames)'}, [false false], true);

% Enable show tracks button
showTracks_h = findobj(data.mainFigure, 'Tag', 'pb_showTracks');
showTracks_h.Enable = 'on';

% Update ranges for kymograph input
ed_kymo_trackID_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackID');
ed_kymo_trackID_h.UserData = {'1', [1 max(trackIDs)], 'integer'};
ed_kymo_trackStart_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackStart');
ed_kymo_trackStart_h.UserData = {'1', [1 numel(data.frames)], 'integer'};
ed_kymo_trackEnd_h = findobj(data.mainFigure, 'Tag', 'ed_kymo_trackEnd');
ed_kymo_trackEnd_h.UserData = {'1', [1 numel(data.frames)], 'integer'};