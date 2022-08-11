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

function bb = addChannel(varargin)

if numel(varargin) == 3
    parent = varargin{3};
else
    parent = varargin{1};
end

tabColor = [0.8490 0.952 1];

if numel(parent.Children) == 0
    boxTitle = 'Main channel';
    channelName = 'PhaseContrast';
    changeChannelName = 'on';
    filenameContains = 'Ph';
else
    boxTitle = sprintf('Additional channel %d', numel(parent.Children));
    channelName = sprintf('Ch%d', numel(parent.Children));
    changeChannelName = 'on';
    filenameContains = sprintf('ch%d', numel(parent.Children));
end

bp = uix.BoxPanel('Parent', parent, 'Title', boxTitle, 'Padding', 5, ...
     'TitleColor', tabColor, 'ForegroundColor', 'black', 'Tag', sprintf('channelField%d', numel(parent.Children)));
 
bb1(1) = uix.VButtonBox('Parent', bp, 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [400, 50]);

bb(2) = uix.HButtonBox('Parent', bb1(1), 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [200, 30], ...
    'VerticalAlignment', 'middle', 'Spacing', 5);

uicontrol('Parent', bb(2), 'Style', 'Text', 'String', 'Channel name', ...
    'HorizontalAlignment', 'left')

uicontrol('Parent', bb(2), 'Style', 'Edit', 'String', channelName, ...
    'HorizontalAlignment', 'left', 'Enable', changeChannelName, 'Tag', sprintf('channelName%d', numel(parent.Children)),...
    'Callback', @checkValidName)

bb(3) = uix.HButtonBox('Parent', bb1(1), 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [200, 30], ...
    'VerticalAlignment', 'middle', 'Spacing', 5);

uicontrol('Parent', bb(3), 'Style', 'Text', 'String', 'Filename contains', ...
    'HorizontalAlignment', 'left')

uicontrol('Parent', bb(3), 'Style', 'Edit', 'String', filenameContains, ...
    'HorizontalAlignment', 'left', 'Tag', sprintf('filenameContains%d', numel(parent.Children)))

uicontrol('Parent', bb(3), 'Style', 'Pushbutton', 'String', 'Update', ...
    'HorizontalAlignment', 'left', 'Callback', @updateFileList)

if numel(parent.Children) > 1
    uicontrol('Parent', bb(3), 'Style', 'Pushbutton', 'String', 'Remove channel', ...
        'HorizontalAlignment', 'left', 'Callback', {@deleteElement, bp})
    set(bp, 'CloseRequestFcn', {@deleteElement, bp});
end