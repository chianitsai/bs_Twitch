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

function toggleMeasurementType(src, ~, plotType)

data = getUIData(src);

fullCell = 0;

switch plotType
    case 'demo' % Demograph
        type_h = findobj(data.mainFigure, 'Tag', 'popm_demo_type');
        type = type_h.Value;
        
        fullCell_h = findobj(data.mainFigure, 'Tag', 'cb_demo_showFullCellWith');
        fullCell = fullCell_h.Value;        
    case 'kymo' % Kymograph
        type_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_type');
        type = type_h.Value;
        
        fullCell_h = findobj(data.mainFigure, 'Tag', 'cb_kymo_showFullCellWith');
        fullCell = fullCell_h.Value;
end

if fullCell
    type_h.Enable = 'Off';
else
    type_h.Enable = 'On';
end