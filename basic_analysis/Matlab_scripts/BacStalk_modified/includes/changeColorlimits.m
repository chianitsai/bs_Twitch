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

function changeColorlimits(src, ~)
data = getUIData(src);

climMin_h = findobj(data.mainFigure, 'Tag', 'ed_climMin');
climMax_h = findobj(data.mainFigure, 'Tag', 'ed_climMax');
climAuto_h = findobj(data.mainFigure, 'Tag', 'cb_climAuto');

if climAuto_h.Value
    climMin_h.Enable = 'Off';
    climMax_h.Enable = 'Off';
    drawnow;
    
    slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
    plotImage(src, [], round(slider_h.Value));
else
    climMin_h.Enable = 'On';
    climMax_h.Enable = 'On';
end

try
    data.axes.main.CLim = [str2double(climMin_h.String) str2double(climMax_h.String)];
end