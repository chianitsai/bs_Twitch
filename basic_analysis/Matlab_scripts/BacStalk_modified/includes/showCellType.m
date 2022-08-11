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

function showCellType(src, ~)
data = getUIData(src);

% Cell types to display
showCellType_h = findobj(data.mainFigure, 'Tag', 'popm_showCellType');
showCellType = showCellType_h.Value;

DetectStalks_h = findobj(data.mainFigure, 'Tag', 'x___HaveStalks');
DetectStalks = DetectStalks_h.Value;
DetectBuds_h = findobj(data.mainFigure, 'Tag', 'x___FormBuds');
DetectBuds = DetectBuds_h.Value;

if DetectStalks && DetectBuds
    switch showCellType
        case 1
            alignmentOption = 1;
        case 2
            % Cells w/o stalks
            alignmentOption = 1;
        case 3
            % Cells w stalks
            alignmentOption = 2;
        case 4
            % Cells w stalks w/o budding cells
            alignmentOption = 2;
        case 5
            % Cells connected to budding cells
            alignmentOption = 3;
        case 6
            % Only buds
            alignmentOption = 1;
        case 7
            % All cells incl. deleted cells
            if ~sum(strcmp(data.settings.measurementsFields, 'Comment'))
                data.settings.measurementsFields = [data.settings.measurementsFields, 'Comment'];
            end
            alignmentOption = 1;
        case 8
            % Deleted cells
            if ~sum(strcmp(data.settings.measurementsFields, 'Comment'))
                data.settings.measurementsFields = [data.settings.measurementsFields, 'Comment'];
            end
            alignmentOption = 1;
    end
end
if DetectStalks && ~DetectBuds
    switch showCellType
        case 1
            alignmentOption = 1;
        case 2
            % Cells w/o stalks
            alignmentOption = 1;
        case 3
            % Cells w stalks
            alignmentOption = 2;
        case 4
            % All cells incl. deleted cells
            if ~sum(strcmp(data.settings.measurementsFields, 'Comment'))
                data.settings.measurementsFields = [data.settings.measurementsFields, 'Comment'];
            end
            alignmentOption = 1;
        case 5
            % Deleted cells
            if ~sum(strcmp(data.settings.measurementsFields, 'Comment'))
                data.settings.measurementsFields = [data.settings.measurementsFields, 'Comment'];
            end
            alignmentOption = 1;
    end
end
if ~DetectStalks && ~DetectBuds
    switch showCellType
        case 1
            alignmentOption = 1;
        case 2
            % All cells incl. deleted cells
            if ~sum(strcmp(data.settings.measurementsFields, 'Comment'))
                data.settings.measurementsFields = [data.settings.measurementsFields, 'Comment'];
            end
            alignmentOption = 1;
        case 3
            % Deleted cells
            if ~sum(strcmp(data.settings.measurementsFields, 'Comment'))
                data.settings.measurementsFields = [data.settings.measurementsFields, 'Comment'];
            end
            alignmentOption = 1;
    end
end


popm_h = findobj(data.mainFigure, '-regexp', 'Tag', 'alignment');
for i = 1:numel(popm_h)
    popm_h(i).String = data.settings.algnmentOptions{alignmentOption};
    popm_h(i).Value = 1;
end
popm_h = findobj(data.mainFigure, '-regexp', 'Tag', 'sort');
for i = 1:numel(popm_h)
    popm_h(i).String = data.settings.sortOptions{alignmentOption};
    popm_h(i).Value = 1;
end


data = createAnalysisTable(data);

setUIData(src, data);

toggleBusyPointer(data, 0)