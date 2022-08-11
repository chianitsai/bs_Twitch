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

function contrainScaleBar(position)
h = gcbf;

data = getUIData(h);

scaling_h = findobj(data.mainFigure, 'Tag', 'Scaling');
scaling = str2double(scaling_h.String);

l_px = hypot(position(2)-position(1), position(4)-position(3));
l_um = scaling*l_px;

data.ui.scalebar.Position = [position(1)+(position(2)-position(1))/2, position(3)+(position(4)-position(3))/2];

if data.ui.scalebar.UserData(2)
    data.ui.scalebar.String = sprintf('%.1f µm', l_um);
    data.ui.scalebar.UserData = [l_um, l_px; 1 0];
else
    data.ui.scalebar.String = sprintf('%.1f px', l_px);
    data.ui.scalebar.UserData = [l_um, l_px; 0 1];
end