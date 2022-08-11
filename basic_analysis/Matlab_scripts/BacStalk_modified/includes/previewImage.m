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

function previewImage(src, eventdata)

data = getUIData(src);

filename = [];

switch lower(src.Type)
    
    case 'uicontrol' % file list
        lb_files = findobj(data.mainFigure, 'tag', 'lb_files');
        
        selectedFiles = lb_files.Value;
        
        if numel(selectedFiles) == 1
            filename = lb_files.String{selectedFiles};
            
            previewStr = sprintf('Preview of image %d', lb_files.Value);
        end
        
    case 'uitable' % file table
        
        if size(eventdata.Indices, 1) == 1
            header = src.ColumnName{eventdata.Indices(2)};
            
            % Check if clicked entry is actually a valid channel
            idx = intersect(data.settings.channelNames, header);
            if ~isempty(idx)
                if sum(cellfun(@(x) ~isempty(x), strfind(data.settings.channelNames, header)))
                    filename = data.frames(eventdata.Indices(1)).(header);
                end
                
                previewStr = sprintf('Preview of %s #%d', header, eventdata.Indices(1));
            end
        end
        
end

if ~isempty(filename)
    img = imread(filename);
    
    data.ui.fb(1).p(1).hb(1).preview.h.Title = previewStr;
    
    imagesc(img, 'Parent', data.axes.preview, 'ButtonDownFcn', {@enlargeImage, previewStr})
    
    colormap(data.axes.preview, gray);
    
    axis(data.axes.preview, 'equal', 'tight');
    removeAxis(data.axes.preview);
end

function enlargeImage(src, ~, titleStr)

data = getUIData(src);

h = figure('Name', titleStr);
h = addIcon(h);
copyobj(data.axes.preview, h);
set(h.Children, 'Units', 'normalized', 'Position', [0 0 1 1]);