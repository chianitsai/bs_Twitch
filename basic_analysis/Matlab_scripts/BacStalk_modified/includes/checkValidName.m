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

function checkValidName(src, ~)

data = getUIData(src);

reservedFields1 = {'Index' 'Frame', 'CellID', 'Time', 'Position',...
    'Area', 'Bud', 'CellLength', 'CellWidth', 'Comment', 'ConnectedWith',...
    'Orientation', 'Stalk', 'StalkLength', 'StalkTouchesEdge',...
    '_BudArea', '_BudLength', '_CellStalkBudLength',...
    '_CellStalkLength', '_StalkBudLength'};

reservedFields2 = {'BrightestFocus', 'MaxCellIntensity',...
    'MeanCellIntensity', 'MedianCellIntensity', 'MinCellIntensity', 'Custom'};

testString = matlab.lang.makeValidName(src.String);

if sum(strcmpi(reservedFields1, testString))
   msgbox(sprintf('"%s" is a reserved measurement name. Please choose another one.',...
       testString), 'Warning', 'warn', 'modal')
   
   testString = ['User_', testString];
end

if sum(cellfun(@(x) ~isempty(x), strfind(reservedFields2, testString)))
   msgbox(sprintf('"%s" is a reserved measurement name. Please choose another one.',...
       testString), 'Warning', 'warn', 'modal')
   
   testString = ['User_', testString];
end

src.String = testString;