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

function updateROI(src, ~, action)
data = getUIData(src);
ROI_h = findobj(data.mainFigure, 'tag', 'ed_ROI');
ROI = str2num(ROI_h.String);

ROI_color_h = findobj(data.mainFigure, 'tag', 'ROIColor');
ROI_color = ROI_color_h.UserData;

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
idx = round(slider_h.Value);
        
switch action
    case 'update'
        plotROI(src)
    case 'clear'
        ROI_rect_h = findobj(data.mainFigure, '-regexp', 'tag', 'ROI_rect');
        delete(ROI_rect_h);
        ROI_h.String = '';
        try
            delete(data.ui.ROI_rect);
        end
        data.frames(idx).roi = []; 
        plotROI(src)
        
    case 'set'
        try
            delete(data.ui.ROI_rect);
        end
        
        h_ax = data.axes.main;
        im_h = findobj(h_ax.Children, 'Type', 'Image');
        img = im_h.CData;
        
        % Disable zoom, pan
        zoom(data.mainFigure, 'off');
        pan(data.mainFigure, 'off');
        
        if ~isempty(ROI)
              rectSize = ROI;
        else
            rectSize = round([mean(h_ax.XLim)-1/4*diff(h_ax.XLim), mean(h_ax.YLim)-1/4*diff(h_ax.YLim),...
                diff(h_ax.XLim)/2, diff(h_ax.YLim)/2]); 
                
            
            if rectSize(1) < 1
                rectSize(1) = 1;
            end
            
            if rectSize(2) < 1
                rectSize(2) = 1;
            end
            
            if rectSize(1)+rectSize(3) > size(img, 1)-1
                rectSize(3) = size(img, 1)-2 - rectSize(1);
            end
            
            if rectSize(2)+rectSize(4) > size(img, 2)-1
                rectSize(3) = size(img, 2)-2 - rectSize(2);
            end
            
            
%             if size(img, 1) > 30 && size(img, 2) > 30
%                 rectSize = [10 10 size(img, 2)-20, size(img, 1)-20];
%             else
%                 rectSize = [1 1 size(img, 2)-1, size(img, 1)-1];
%             end
            ROI = rectSize;
        end
        
        ROI_h.String = strrep(num2str(rectSize), '   ', ' ');
        plotROI(src)
        
        h_rect = imrect(h_ax, rectSize);
        h_rect.setColor(ROI_color)
        xlimits = [0 size(img, 1)];
        xlimits(1) = xlimits(1)+1;
        xlimits(2) = xlimits(2)-1;
        ylimits = [0 size(img, 2)];
        ylimits(1) = ylimits(1)+1;
        ylimits(2) = ylimits(2)-1;
        fcn = makeConstrainToRectFcn('imrect',xlimits,ylimits);
        addNewPositionCallback(h_rect, @rect_ROI_Callback);
        setPositionConstraintFcn(h_rect,fcn);
        
        data.ui.ROI_rect = h_rect;
        
        data.frames(idx).roi = ROI; 
        
        
    case 'applyAll'
        ROIs = repmat({ROI}, numel(data.frames), 1);
        [data.frames.roi] = ROIs{:}; 

    case 'zoom'
        if isfield(data.ui, 'ROI_rect')
            if isvalid(data.ui.ROI_rect)
                delete(data.ui.ROI_rect);
                drawnow;
            end
        end
        
end

setUIData(data.mainFigure, data);