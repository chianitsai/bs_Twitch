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

function multiChannelGraph(src, ~)

data = getUIData(src);

f = figure('Name', 'Multi-channel demo-/kymograph');
f = addIcon(f);
toRemove = findobj(findall(f));
delete(toRemove(2:end));

g = uix.Grid('Parent', f, 'Padding', 10, 'Spacing', 10);

% 1st column
uicontrol('Parent', g, 'Style', 'Text', 'String', 'Select 1st fig-file', ...
    'HorizontalAlignment', 'left');
uicontrol('Parent', g, 'Style', 'Edit', 'String', '', ...
    'HorizontalAlignment', 'left', 'Tag', 'File1');
uicontrol('Parent', g, 'Style', 'Text', 'String', 'Select 2nd fig-file', ...
    'HorizontalAlignment', 'left');
uicontrol('Parent', g, 'Style', 'Edit', 'String', '', ...
    'HorizontalAlignment', 'left', 'Tag', 'File2');
uicontrol('Parent', g, 'Style', 'Text', 'String', 'Select 3rd fig-file', ...
    'HorizontalAlignment', 'left');
uicontrol('Parent', g, 'Style', 'Edit', 'String', '', ...
    'HorizontalAlignment', 'left', 'Tag', 'File3');
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', 'Create multichannel graph', ...
    'Callback', {@multichannel_create, data.guiPath});

% 2nd column
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', 'Browse', ...
    'HorizontalAlignment', 'left', 'Callback', {@multichannel_selectFile, data.guiPath, 1});
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', 'Browse', ...
    'HorizontalAlignment', 'left', 'Callback', {@multichannel_selectFile, data.guiPath, 2});
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', 'Browse', ...
    'HorizontalAlignment', 'left', 'Callback', {@multichannel_selectFile, data.guiPath, 3});
uix.Empty('Parent', g);
uix.Empty('Parent', g);

%3rd column
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Text', 'String', 'Color', ...
    'HorizontalAlignment', 'right');
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Text', 'String', 'Color', ...
    'HorizontalAlignment', 'right');
uix.Empty('Parent', g);
uicontrol('Parent', g, 'Style', 'Text', 'String', 'Color', ...
    'HorizontalAlignment', 'right');
uix.Empty('Parent', g);
uix.Empty('Parent', g);

%4th column
uix.Empty('Parent', g);
h = uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', '', ...
    'Tag', 'Color1', 'UserData', [1 0 0]);
c = [1 0 0];
h.BackgroundColor = c;
h.Callback = @changeColor;

uix.Empty('Parent', g);
h = uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', '', ...
    'Tag', 'Color2', 'UserData', [0 1 0]);
c = [0 1 0];
h.BackgroundColor = c;
h.Callback = @changeColor;

uix.Empty('Parent', g);
h = uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', '', ...
    'Tag', 'Color3', 'UserData', [0 0 1]);
c = [0 0 1];
h.BackgroundColor = c;
h.Callback = @changeColor;
uix.Empty('Parent', g);
uix.Empty('Parent', g);

set(g, 'Widths', [-1 60 40 30], 'Heights', [20 25 20 25 20 25 20 25]);

pos = f.Position;
f.Units = 'pixels';
pos(3) = 400;
pos(4) = sum(g.Heights)+30+6*10;
f.Position = pos;

function multichannel_selectFile(src, ~, guiPath, fileIdx)
edit_h = findobj(gcf, 'Tag', sprintf('File%d', fileIdx));

% Load previous directory
if isdeployed
    if exist('directory.mat','file')
        load('directory.mat');
    else
        directory = '';
    end
else
    if exist(fullfile(guiPath, 'includes', 'directory.mat'),'file')
        load('directory.mat');
    else
        directory = guiPath;
    end
end

[filename, directory] = uigetfile('*.fig', sprintf('Select fig-file for channel #%d', fileIdx), directory);

% Save current directory
if directory
    edit_h.String = fullfile(directory, filename);
end

function multichannel_create(src, ~, guiPath)
h = [];
for i = 1:3
    file_h = findobj(ancestor(src,'figure', 'toplevel'), 'Tag', sprintf('File%d', i));
    color_h = findobj(ancestor(src,'figure', 'toplevel'), 'Tag', sprintf('Color%d', i));
    try
        if ~isempty(file_h.String)
            h{i} = openfig(file_h.String);
            
            img_h = findobj(h{i}, 'Type', 'image');
            img = img_h.CData;
            
            if size(img, 3) == 3
                for j = 1:3
                    try
                        delete(h{j});
                    end
                end
                msgbox('RGB-images are not supported!', 'Error', 'error', 'modal');
                return;
            end
            
            cLimits = img_h.Parent.CLim;
            img = (img-cLimits(1))/(cLimits(2)-cLimits(1));
            
            if ~exist('CData_new', 'var')
                CData_new = zeros(size(img, 1), size(img, 2), 3);
                h_idx = i;
                titleStr = h{i}.Name;
            else
                titleStr = [titleStr, ' & ', h{i}.Name];
            end
            
            try
                for cc = 1:3
                    CData_new(:,:,cc) = CData_new(:,:,cc) + color_h.UserData(cc) * img;
                end
            catch
                for j = 1:3
                    try
                        delete(h{j});
                    end
                end
                msgbox('Content does not match!', 'Error', 'error', 'modal');
                return;
            end
        end
    catch
        msgbox(sprintf('File "%s" could not be opened and will be ignored!', file_h.String), 'Warning', 'warn', 'modal');
    end
end

if exist('h_idx', 'var')
    for i = 1:3
        if i ~= h_idx
            try
                delete(h{i});
            end
        end
    end
    
    CData_new(CData_new>1) = 1;
    img_h = findobj(h{h_idx}, 'Type', 'image');
    img_h.CData = CData_new;
    img_h.Parent.CLim = [0 1];
    colorbar(img_h.Parent, 'off');
    h{h_idx}.Name = titleStr;
    figure(h{h_idx});
else
    msgbox('Please select files first.', 'Help', 'help', 'modal');
end
