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

function updateTableStyle(src, tableData, columnNames)

jscrollpane = findjobj(src);

jtable = jscrollpane.getViewport.getView;

jtable.setModel(javax.swing.table.DefaultTableModel(tableData, columnNames))

jtable.getTableHeader.setBackground(java.awt.Color(1, 1, 1))    
%jtable.getTableHeader.setOpaque(true);
%jtable.getTableHeader.setForeground(java.awt.Color(0,0,0))    

sclass=java.lang.String('').getClass;
editor=jtable.getDefaultEditor(sclass);
editor.getComponent.setEditable(0);
%editor.setClickCountToStart(20);

rowHeaderViewport=jscrollpane.getComponent(0);
rowHeader=rowHeaderViewport.getComponent(0);
rowHeader.setBackground(java.awt.Color(1, 1, 1));

theader = com.jidesoft.grid.AutoFilterTableHeader(jtable);
theader.setAutoFilterEnabled(true)
theader.setShowFilterName(true)
theader.setShowFilterIcon(true)
jtable.setTableHeader(theader)

% if isempty(src.UserData)
%     return;
% end

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

    cr0.setForeground(java.awt.Color(0,0,0))
    cr0.setBackground(java.awt.Color(1,1,1))

    jtable.getColumnModel.getColumn(i).setCellRenderer(cr0)
    jtable.getColumnModel.getColumn(i).setCellEditor(editor)
end
drawnow;
jtable.repaint;