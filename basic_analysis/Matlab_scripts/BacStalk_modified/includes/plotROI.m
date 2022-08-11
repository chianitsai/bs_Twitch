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

function plotROI(src, ~)

data = getUIData(src);

ROI_h = findobj(data.mainFigure, 'tag', 'ed_ROI');
ROI = str2num(ROI_h.String);

UseBinaryMasks_h = findobj(data.mainFigure, 'Tag', 'UseBinaryMasks');

if UseBinaryMasks_h.Value
    CellSize = 0;
else
    CellSize_h = findobj(data.mainFigure, 'Tag', 'CellSize');
    CellSize = str2num(CellSize_h.String);
    if ~checkInput(CellSize_h)
        return;
    end
end

ROI_rect_h = findobj(data.mainFigure, 'tag', 'ROI_rect');
ROI_rect_inner_h = findobj(data.mainFigure, 'tag', 'ROI_rect_inner');

ROI_color_h = findobj(data.mainFigure, 'tag', 'ROIColor');
ROI_color = ROI_color_h.UserData;

try
    ROI_rect_h.EdgeColor = ROI_color;
end
try
    ROI_rect_inner_h.EdgeColor = ROI_color;
end


im_h = findobj(data.axes.main, 'Type', 'Image');
img = im_h.CData;

% Check valid size of ROI
if isempty(ROI) || numel(ROI) < 4 || sum(arrayfun(@(x) x<1, ROI)) || (ROI(1) + ROI(3)) > size(img, 1) || (ROI(2) + ROI(4)) > size(img, 2)
    ROI_h.String = '';
    ROI = [];
    delete(ROI_rect_h);
    delete(ROI_rect_inner_h);
    
    try
        delete(data.ui.ROI_rect);
    end
    
    if ~isempty(ROI) && (numel(ROI) < 4 || sum(arrayfun(@(x) x<1, ROI)) || (ROI(1) + ROI(3)) > size(img, 1) || (ROI(2) + ROI(4)) > size(img, 2))
        msgbox('The size of the region of interest is not valid!', 'Error', 'error', 'modal');
    end
end

% plotting
if ~isempty(ROI)
    plotOuterROI = true;
else
    plotOuterROI = false;
    ROI = [0 0 size(img, 2) size(img, 1)];
end

%ROI_inner = [ROI(1:2)+5*CellSize ROI(3:4)-2*5*CellSize];
% Don't chnage size of inner ROI
ROI_inner = [[0 0] + 5*CellSize [size(img, 2) size(img, 1)]-2*5*CellSize];

if ~isempty(ROI_rect_h)
    if plotOuterROI
        ROI_rect_h.Position = ROI;
    end
        
    try
        data.ui.ROI_rect.setPosition(ROI);
    end

else
    
    
    if plotOuterROI
        h = rectangle('Position',ROI, 'EdgeColor', ROI_color, 'Tag', 'ROI_rect', ...
            'Parent', data.axes.main, 'ButtonDownFcn', {@updateROI, 'set'});
        uistack(h, 'down', numel(data.axes.main.Children)-2);
    end
    
    
end

if ROI_inner(3) < 0 || ROI_inner(4) < 0
    minCellSize = floor(min([size(img, 2) size(img, 1)])/10);
    msgbox({'The image is not compatible with the entered cell size (the dashed rectangle does not fit)!', 'Either provide a larger image (in pixels) or reduce the cell size.', ...
        sprintf('The maximum allowed cell size for this image is %d.', minCellSize)}, 'Error', 'error', 'modal');
    CellSize_h = findobj(data.mainFigure, 'Tag', 'CellSize');
    CellSize_h.String = num2str(minCellSize);
    return;
end
try
    ROI_rect_inner_h.Position = ROI_inner;
catch
    h = rectangle('Position',ROI_inner, 'EdgeColor', 'b', 'Tag', 'ROI_rect_inner', 'EdgeColor', ROI_color, 'LineStyle', '--', 'Parent', data.axes.main);
    uistack(h, 'down', numel(data.axes.main.Children)-2);
end
