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

function adjustColorlimits(data)
climMin_h = findobj(data.mainFigure, 'Tag', 'ed_climMin');
climMax_h = findobj(data.mainFigure, 'Tag', 'ed_climMax');
climAuto_h = findobj(data.mainFigure, 'Tag', 'cb_climAuto');


if climAuto_h.Value
    popm_channel_h = findobj(data.mainFigure, 'Tag', 'popm_channel');
    popm_colormap_h = findobj(data.mainFigure, 'Tag', 'popm_colormap');
    ch = popm_channel_h.String{popm_channel_h.Value};
    im_h = findobj(data.axes.main, 'Type', 'image');
    img = im_h.CData;
    % Reset colormap
    if ~strcmp(ch, 'PhaseContrast')
       cLimits = [prctile(img(:), 30) prctile(img(:), 99.99)];
    else % PhaseContrast
       cLimits = [min(img(:)) max(img(:))];
       colormap(data.axes.main, gray(1000));
       popm_colormap_h.Value = 1;
    end
    data.axes.main.CLim = cLimits;
    
    climMin_h.String = num2str(cLimits(1));
    climMax_h.String = num2str(cLimits(2));
else
    data.axes.main.CLim = [str2double(climMin_h.String) str2double(climMax_h.String)];
end