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

function bb = addMetadata(varargin)

if numel(varargin) == 3
    parent = varargin{3};
else
    parent = varargin{1};
end

tabColor = [0.6784 0.9176 0.8549];

boxTitle = sprintf('Metadata %d', numel(parent.Children)+1);
changeChannelName = 'on';

filenameContains1 = sprintf('_t', numel(parent.Children)+1);
filenameContains2 = sprintf('.', numel(parent.Children)+1);

if numel(parent.Children) < 2
    metadataSelection = numel(parent.Children)+1;
    isnumericData = true;
else
    metadataSelection = 3;
    isnumericData = false;
end
    
bp = uix.BoxPanel('Parent', parent, 'Title', boxTitle, 'Padding', 5, ...
     'TitleColor', tabColor, 'ForegroundColor', 'black', 'Tag', sprintf('metadataField%d', numel(parent.Children)));
set(bp, 'CloseRequestFcn', {@deleteElement, bp});

bb1(1) = uix.VButtonBox('Parent', bp, 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [400, 50]);

bb(2) = uix.HButtonBox('Parent', bb1(1), 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [200, 30], ...
    'VerticalAlignment', 'middle', 'Spacing', 5);

uicontrol('Parent', bb(2), 'Style', 'Text', 'String', 'Metadata type', ...
    'HorizontalAlignment', 'left')

uicontrol('Parent', bb(2), 'Style', 'Popupmenu', 'String', {'Time', 'Position', 'Custom'}, ...
    'HorizontalAlignment', 'left', 'Enable', changeChannelName,...
    'Callback', @selectMetadata, 'Value', metadataSelection, 'Tag', sprintf('metadataName%d', numel(parent.Children)))

bb(3) = uix.HButtonBox('Parent', bb1(1), 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [200, 30], ...
    'VerticalAlignment', 'middle', 'Spacing', 5);

uicontrol('Parent', bb(3), 'Style', 'Text', 'String', 'Start with', ...
    'HorizontalAlignment', 'left')

uicontrol('Parent', bb(3), 'Style', 'Edit', 'String', filenameContains1, ...
    'HorizontalAlignment', 'left', 'Tag', sprintf('filenameStart%d', numel(parent.Children)))

uix.Empty('Parent', bb(3));

uicontrol('Parent', bb(3), 'Style', 'Checkbox', 'String', 'Numeric data', ...
    'HorizontalAlignment', 'left', 'Tag', sprintf('isNumeric%d', numel(parent.Children)),...
    'Value', isnumericData)

bb(4) = uix.HButtonBox('Parent', bb1(1), 'VerticalAlignment', 'top' ,...
    'HorizontalAlignment', 'left', 'ButtonSize', [200, 30], ...
    'VerticalAlignment', 'middle', 'Spacing', 5);

uicontrol('Parent', bb(4), 'Style', 'Text', 'String', 'Capture until', ...
    'HorizontalAlignment', 'left')

uicontrol('Parent', bb(4), 'Style', 'Edit', 'String', filenameContains2, ...
    'HorizontalAlignment', 'left', 'Tag', sprintf('filenameEnd%d', numel(parent.Children)))

uicontrol('Parent', bb(4), 'Style', 'Pushbutton', 'String', 'Remove metadata', ...
    'HorizontalAlignment', 'left', 'Callback', {@deleteElement, bp})

uicontrol('Parent', bb(4), 'Style', 'Pushbutton', 'String', 'Update', ...
    'HorizontalAlignment', 'left', 'Callback', @updateFileList)

function selectMetadata(src, ~)
if src.Value == 3
    src.Style = 'edit';
    src.String = 'Custom';
    src.Value = 1;
    src.Callback = @checkValidName;
else
    src.Callback = @selectMetadata;
end

