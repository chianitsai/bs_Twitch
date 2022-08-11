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

function [img, file] = plotImage(src, ~, idx)
data = getUIData(src);

if nargin < 3
    slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
    idx = round(slider_h.Value);
end

% Get channel
popm_channel_h = findobj(data.mainFigure, 'Tag', 'popm_channel');
ch = popm_channel_h.String{popm_channel_h.Value};

% Get metadata
metadataInfo = '';
for m = 1:numel(data.settings.metadataNames)
    if m == 1
        metadataInfo = '  -  Metadata: ';
    end
    if isnumeric(data.frames(idx).(data.settings.metadataNames{m}))
        metadataInfo = [metadataInfo, sprintf('%s = %d', data.settings.metadataNames{m}, ...
            data.frames(idx).(data.settings.metadataNames{m}))];
    else
        metadataInfo = [metadataInfo, sprintf('%s = "%s"', data.settings.metadataNames{m}, ...
            data.frames(idx).(data.settings.metadataNames{m}))];
    end
    if m < numel(data.settings.metadataNames)
        metadataInfo = [metadataInfo, ', '];
    end
end

data.axes.main.Parent.Title = sprintf('Image %d/%d (%s) %s', ...
    idx, numel(data.frames), ch, metadataInfo);


file = data.frames(idx).(ch);

if isfield(data.settings, 'previousImage')
    if strcmp(file, data.settings.previousImage)
        % Image is already loaded
        img = [];
        adjustColorlimits(data)
        return;
    end
end

img = imread(file);

% Correct shift
if isfield(data.frames, 'tform')
    if ~isempty(data.frames(idx).tform)
        img = imwarp(img, data.frames(idx).tform, 'OutputView', imref2d(size(img)), 'Interp', 'linear', 'FillValues', mean(img(:)));
    end
end

im = findobj(data.axes.main, 'Type', 'image');

if isempty(im)
    imagesc(img, 'Parent', data.axes.main, 'UIContextMenu', data.ui.m.c1, 'ButtonDownFcn', @clickImage);
    set(data.axes.main, 'XTick', [], 'YTick', []);
    colormap(data.axes.main, gray(1000));
    axis(data.axes.main, 'equal', 'off');
else
    im.CData = img;
end
adjustColorlimits(data)

% Reset zoom
if data.axes.main.XLim(2) > size(img,1) && data.axes.main.YLim(2) > size(img,2) 
    zoom(data.axes.main, 'reset');
end

