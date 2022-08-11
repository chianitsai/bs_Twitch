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

function reverseOrientation(src, ~, objectId)

data = getUIData(src);

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');

cells = data.frames(round(slider_h.Value)).cells;

if cells.Stats(objectId).Stalk || cells.Stats(objectId).Bud
    showNote(data.axes.main, [cells.Stats(objectId).CellMedialAxisCoordinates(round(end/2),2), cells.Stats(objectId).CellMedialAxisCoordinates(round(end/2),1)], 'You cannot swap the orientation of a budding cell or cell with a stalk!', 'orange')
else
    
    cells.Stats(objectId).CellMedialAxisIdx = flip(cells.Stats(objectId).CellMedialAxisIdx);
    cells.Stats(objectId).CellMedialAxisCoordinates = flip(cells.Stats(objectId).CellMedialAxisCoordinates);
    
    fNames = fieldnames(cells.Stats(objectId));
    
    % Flip intensity measurements
    idx = find(cellfun(@(x) ~isempty(x), strfind(fNames, 'MedialAxisIntensity')));
    for i = 1:numel(idx)
        cells.Stats(objectId).(fNames{idx(i)}) = flip(cells.Stats(objectId).(fNames{idx(i)}));
    end
    
    % Flip also the distance from pole measurement
    idx1 = find(cellfun(@(x) ~isempty(x), regexp(fNames, regexptranslate('wildcard', 'BrightestFocus*Distance'))));
    idx2 = find(cellfun(@(x) ~isempty(x), regexp(fNames, regexptranslate('wildcard', 'BrightestFocus*DistanceToCellCenter'))));
    idx1 = setdiff(idx1, idx2);
    
    % Flip Distance
    for i = 1:numel(idx1)
        cells.Stats(objectId).(fNames{idx1(i)}) = cells.Stats(objectId).CellLength - cells.Stats(objectId).(fNames{idx1(i)});
    end
    
    % Invert DistanceA_ToCellCenter
    for i = 1:numel(idx2)
        cells.Stats(objectId).(fNames{idx2(i)}) = -1*cells.Stats(objectId).(fNames{idx2(i)});
    end
    
    cells.Handles(objectId).medialAxisOrientation.YData = cells.Stats(objectId).CellMedialAxisCoordinates(1,1);
    cells.Handles(objectId).medialAxisOrientation.XData = cells.Stats(objectId).CellMedialAxisCoordinates(1,2);

    data.frames(round(slider_h.Value)).cells = cells;
    setUIData(data.mainFigure, data);
end