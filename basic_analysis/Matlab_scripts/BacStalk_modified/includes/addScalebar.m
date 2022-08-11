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

function addScalebar(src, ~, type)

data = getUIData(src);

showCellDetectionTab(src, [])
drawnow;

switch type
    case 'scalebar'
        prompt = {'Enter size of scale bar (in microns)'};
        dlg_title = 'Input';
        num_lines = 1;
        defaultans = {'100'};
        answer = str2double(inputdlg(prompt,dlg_title,num_lines,defaultans));
    case 'distance'
        answer = 1;
end


if answer
    scaling_h = findobj(data.mainFigure, 'Tag', 'Scaling');
    scaling = str2double(scaling_h.String);
    
    im_h = findobj(data.axes.main, 'Type', 'image');
    XLim = data.axes.main.XLim;
    YLim = data.axes.main.YLim;
    
    if XLim(1) < im_h.XData(1)
        XLim(1) = im_h.XData(1);
    end
    if XLim(2) > im_h.XData(2)
        XLim(2) = im_h.XData(2);
    end
    if YLim(1) < im_h.YData(1)
        YLim(1) = im_h.YData(1);
    end
    if YLim(2) > im_h.YData(2)
        YLim(2) = im_h.YData(2);
    end
    
    switch type
        case 'scalebar'
            position = [XLim(2)-0.1*(XLim(2)-XLim(1))-1/scaling*answer, YLim(1)+0.1*(YLim(2)-YLim(1)); XLim(2)-0.1*(XLim(2)-XLim(1)), YLim(1)+0.1*(YLim(2)-YLim(1))];
        case 'distance'
            position = [XLim(2)-0.75*(XLim(2)-XLim(1)), YLim(1)+0.5*(YLim(2)-YLim(1)); XLim(2)-0.25*(XLim(2)-XLim(1)), YLim(1)+0.5*(YLim(2)-YLim(1))];
    end
    
    if isfield(data.ui, 'scalebar_line')
        if isvalid(data.ui.scalebar_line)
            delete(data.ui.scalebar);
            delete(data.ui.scalebar_line);
        end
    end
    
    h_line = imline(data.axes.main, position);
    
    l_px = hypot(position(2)-position(1), position(4)-position(3));
    l_um = l_px*scaling;
   
    switch type 
        case 'scalebar'
            scalebar_text_h = text(position(1)+(position(2)-position(1))/2, position(3)+(position(4)-position(3))/2, sprintf('%.1f \\mum', l_um), ...
                'BackgroundColor', 'w', 'Tag', 'scalebar',...
                'Parent', data.axes.main,...
                'HorizontalAlignment', 'center', 'uicontextmenu', data.ui.m.m4, 'ButtonDownFcn', @changeScalebarLabel, 'UserData', [l_um, l_px; 1 0]);
            
        case 'distance'
            scalebar_text_h = text(position(1)+(position(2)-position(1))/2, position(3)+(position(4)-position(3))/2, sprintf('%.1f px (click to change unit)', l_px), ...
                'BackgroundColor', 'w', 'Tag', 'scalebar',...
                'Parent', data.axes.main,...
                'HorizontalAlignment', 'center', 'uicontextmenu', data.ui.m.m4, 'ButtonDownFcn', @changeScalebarLabel, 'UserData', [l_um, l_px; 0 1]);
            
    end
    setColor(h_line, [1 1 1]);
    addNewPositionCallback(h_line, @contrainScaleBar);
    
    data.ui.scalebar_line = h_line;
    data.ui.scalebar = scalebar_text_h;
    
    setUIData(data.mainFigure, data);
end
