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

function toggleDetectStalks(src, ~)

data = getUIData(src);

CellExpansionWidth_h = findobj(data.mainFigure, 'Tag', 'CellExpansionWidth');
StalkScreeningLength_h = findobj(data.mainFigure, 'Tag', 'StalkScreeningLength');
MinStalkLength_h = findobj(data.mainFigure, 'Tag', 'MinStalkLength');
MaxStalkFlexibility_h = findobj(data.mainFigure, 'Tag', 'MaxStalkFlexibility');
StalkScreeningWidth_h = findobj(data.mainFigure, 'Tag', 'StalkScreeningWidth');
StalkSensitivity_h = findobj(data.mainFigure, 'Tag', 'StalkSensitivity');

if ~src.Value 
    'off'
    CellExpansionWidth_h.Enable = 'off';
    StalkScreeningLength_h.Enable = 'off';
    MinStalkLength_h.Enable = 'off';
    MaxStalkFlexibility_h.Enable = 'off';
    StalkScreeningWidth_h.Enable = 'off';
    StalkSensitivity_h.Enable = 'off';
else
    'on'
    CellExpansionWidth_h.Enable = 'on';
    StalkScreeningLength_h.Enable = 'on';
    MinStalkLength_h.Enable = 'on';
    MaxStalkFlexibility_h.Enable = 'on';
    StalkScreeningWidth_h.Enable = 'on';
    StalkSensitivity_h.Enable = 'on';
end
