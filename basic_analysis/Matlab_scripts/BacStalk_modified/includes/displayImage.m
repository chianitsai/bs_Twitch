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

function displayImage(src, ~, idx)

data = getUIData(src);

if ~isfield(data, 'frames')
    return;
end

toggleBusyPointer(data, 1)

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');

if nargin < 3
    idx = round(slider_h.Value);
else
    slider_h.Value = idx;
end

%Delete all overlays exept ROI-related ones
%delete(findobj(data.axes.main, 'Type', 'text'))
delete(findobj(data.axes.main, '-regexp', 'Tag', 'cell'))

[img, file] = plotImage(src, [], idx);

data.settings.previousImage = file;

% Determine if cells were determined
if isfield(data.frames, 'cells')
    if ~isempty(data.frames(idx).cells)
        isCells = true;
        cells = data.frames(idx).cells;
    else
        isCells = false;
        cells = [];
    end
else
    isCells = false;
    cells = [];
end
if isempty(cells)
    isCells = false;
end
        
if isfield(data.ui, 'scalebar_line')
    if ~isvalid(data.ui.scalebar_line)
        delete(data.ui.scalebar);
    end
end
%delete(findobj(data.axes.main, '-regexp', 'Tag', 'track'))

% Update ROI rectangle
if isfield(data.frames, 'roi')
    try
        % Delete the draggable ROI
        delete(data.ui.ROI_rect);
        %data.ui.ROI_rect.setColor(ROI_color);
    end

    ROI_h = findobj(data.mainFigure, 'tag', 'ed_ROI');
    if ~isempty(data.frames(idx).roi) 
        ROI_h.String = strrep(num2str(data.frames(idx).roi), '   ', ' ');
    else
        updateROI(src, [], 'clear')
    end
end
plotROI(src)

% Display overlays
cb_overlays_h = findobj(data.mainFigure, 'Tag', 'cb_overlays');
if cb_overlays_h.Value
    if isCells
        th = text(mean(data.axes.main.XLim),mean(data.axes.main.YLim), 'Drawing overlays...', ...
            'Parent', data.axes.main, 'HorizontalAlignment', 'center');
        drawnow;
        cells = plotOverlays(data, cells);
        delete(th);
        data.frames(idx).cells = cells;
    end
end

% Show cells
updateCellTable(data, cells)

setUIData(data.mainFigure, data);
toggleBusyPointer(data, 0)