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

function cellRibbon = getCellRibbon(singleCellStats, imSize, scaling)

cellRibbon = cell(1, numel(singleCellStats.CellMedialAxisIdx));
%figure; hold on;
medialAxisCoords = singleCellStats.CellMedialAxisCoordinates;
outlineCoords = singleCellStats.CellOutlineCoordinates;
cellWidth = singleCellStats.CellWidth;
cZ = cellWidth;

%plot(outlineCoords(:,1), outlineCoords(:,2))
%plot(medialAxisCoords(:,1), medialAxisCoords(:,2))
for m = 1:1:size(medialAxisCoords,1)
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
    
    %plot(medialAxisCoords(m,1), medialAxisCoords(m,2), 'o')
    %plot(l1_1, l2_1, 'Color', 'black')
    %plot(l1_2, l2_2, 'Color', 'black')
    cellRibbon{m} = sub2ind(imSize, [l1_1, l1_2]', [l2_1, l2_2]');
end