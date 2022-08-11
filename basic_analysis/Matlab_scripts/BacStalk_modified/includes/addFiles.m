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

function addFiles(src, ~,filename,directory)
data = getUIData(src);

% % Load previous directory
% if isdeployed
%     pathstr = fileparts(which('directory.mat'));
%     load('directory.mat');
% else
%     if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
%         load('directory.mat');
%     else
%         directory = data.guiPath;
%     end
% end
% 
% [filename, directory] = uigetfile( ...
%     {'*.jpeg;*.jpg;*.tif;*.tiff;',...
%     'Image files (*.jpeg,*.jpg,*.tif,*.tiff,*.png)';
%     '*.*',  'All Files (*.*)'}, 'MultiSelect', 'on', ...
%     'Select images', directory);

% Save current directory
if directory
    if isdeployed
        save(fullfile(pathstr, 'directory.mat'), 'directory');
    else
        save(fullfile(data.guiPath, 'includes', 'directory.mat'), 'directory');
    end
else
    disp('No folder selected');
    return;
end


lb_files = findobj(data.mainFigure, 'tag', 'lb_files');

if ~iscell(filename)
    filename = {filename};
end

filename = cellfun(@(path, fname) fullfile(path, fname), repmat({directory}, 1, numel(filename)),...
    filename, 'UniformOutput', false);

lb_files.String = [lb_files.String; filename'];
lb_files.Max = numel(lb_files.String);

if numel(lb_files.String) > 0
    eventdata = struct('Indices', [1 1]);
    previewImage(lb_files, eventdata)
end