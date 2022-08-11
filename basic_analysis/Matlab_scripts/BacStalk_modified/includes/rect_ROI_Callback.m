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

function rect_ROI_Callback(pos)

h_fig = gcf;

ROI_h = findobj(h_fig, 'tag', 'ed_ROI');
ROI = strrep(num2str(round(pos)), '   ', ' ');
ROI_h.String = ROI;

% Update ROI in frames-table
data = getUIData(h_fig);
slider_h = findobj(h_fig, 'Tag', 'slider_im');
idx = round(slider_h.Value);
data.frames(idx).roi = ROI;
setUIData(h_fig, data);

% Plot updated ROI
plotROI(h_fig);