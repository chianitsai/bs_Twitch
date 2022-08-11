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

function updateSlider(data)

slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');

slider_h.Min = 1;
slider_h.Max = numel(data.frames);

if slider_h.Value < slider_h.Min || slider_h.Value > slider_h.Max
    slider_h.Value = slider_h.Min;
end

try
    slider_h.SliderStep = [1 1]/(slider_h.Max - slider_h.Min);
    slider_h.Enable = 'on';
catch
    slider_h.Enable = 'off';
end
    
    