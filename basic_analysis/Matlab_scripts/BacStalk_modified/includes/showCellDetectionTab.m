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

function showCellDetectionTab(src, ~)

data = getUIData(src);

if ~isfield(data, 'frames')
    data.ui.tabGroup.SelectedTab = data.ui.tabGroup.Children(1);
    msgbox('Please add images first!', 'No images added', 'help', 'modal');
    return;
end

if isempty(data.axes.main.Children)
    displayImage(src, [], 1);
end

% Select tab
data.ui.tabGroup.SelectedTab = data.ui.tabGroup.Children(2);

data.ui.m.m2.Enable = 'on';