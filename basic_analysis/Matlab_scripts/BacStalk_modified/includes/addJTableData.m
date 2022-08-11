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

function addJTableData(src)
jscrollpane = findjobj(src);

jtable = jscrollpane.getViewport.getView;

% Replacing the tables content
for i = 0:jtable.getColumnCount-1
    if islogical(src.UserData{1,i+1})
        cr0 = com.jidesoft.grid.BooleanCheckBoxCellRenderer;
    end
    
    if isnumeric(src.UserData{1,i+1})
        cr0 = com.jidesoft.grid.NumberCellRenderer;
    end
    
    if ischar(src.UserData{1,i+1})
        cr0 = com.jidesoft.grid.MultilineTableCellRenderer;
    end
    
    for r = 0:size(src.UserData, 1)-1
        jtable.getModel.setValueAt(src.UserData{r+1,i+1},r,i)
    end
    jtable.getColumnModel.getColumn(i).setCellRenderer(cr0)
end


