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

function applyPreSettings(src, ~, type)

data = getUIData(src);

HaveStalks_h = findobj(data.mainFigure, 'Tag', 'x___HaveStalks');
HaveStalks_h.Callback = {@applyPreSettings, 'stalks'};
FormBuds_h = findobj(data.mainFigure, 'Tag', 'x___FormBuds');
FormBuds_h.Callback = {@applyPreSettings, 'buds'};
popm_showCellType_h = findobj(data.mainFigure, 'Tag', 'popm_showCellType'); 
popm_kymo_alignment_h = findobj(data.mainFigure, 'Tag', 'popm_kymo_alignment'); 

switch type
    case 'stalks'
        
        CellExpansionWidth_h = findobj(data.mainFigure, 'Tag', 'CellExpansionWidth');
        StalkScreeningLength_h = findobj(data.mainFigure, 'Tag', 'StalkScreeningLength');
        MinStalkLength_h = findobj(data.mainFigure, 'Tag', 'MinStalkLength');
        MaxStalkFlexibility_h = findobj(data.mainFigure, 'Tag', 'MaxStalkFlexibility');
        StalkScreeningWidth_h = findobj(data.mainFigure, 'Tag', 'StalkScreeningWidth');
        StalkSensitivity_h = findobj(data.mainFigure, 'Tag', 'StalkSensitivity');
        ExcludeCellsCloseBy_h = findobj(data.mainFigure, 'Tag', 'ExcludeCellsCloseBy');
        
        if ~HaveStalks_h.Value
            'setting off'
            switchElement(CellExpansionWidth_h, 'off');
            switchElement(StalkScreeningLength_h, 'off');
            switchElement(MinStalkLength_h, 'off');
            switchElement(MaxStalkFlexibility_h, 'off');
            switchElement(StalkScreeningWidth_h, 'off');
            switchElement(StalkSensitivity_h, 'off');
            switchElement(ExcludeCellsCloseBy_h, 'off');
            ExcludeCellsCloseBy_h.Value = false;
            
            FormBuds_h.Enable = 'off';
            FormBuds_h.Value = false;
        elseif y
            'setting on'
            switchElement(CellExpansionWidth_h, 'on');
            switchElement(StalkScreeningLength_h, 'on');
            switchElement(MinStalkLength_h, 'on');
            switchElement(MaxStalkFlexibility_h, 'on');
            switchElement(StalkScreeningWidth_h, 'on');
            switchElement(StalkSensitivity_h, 'on');
            switchElement(ExcludeCellsCloseBy_h, 'on');
            ExcludeCellsCloseBy_h.Value = true;
            
            FormBuds_h.Enable = 'on';
        end
end

popm_showCellType_h.Value = 1;
popm_kymo_alignment_h.Value = 1;

if ~FormBuds_h.Value
    if HaveStalks_h.Value
        popm_showCellType_h.String = data.settings.displayCellOptions{2};
        popm_kymo_alignment_h.String = data.settings.algnmentOptions{2};
        
    else
        popm_showCellType_h.String = data.settings.displayCellOptions{1};
        popm_kymo_alignment_h.String = data.settings.algnmentOptions{1};
    end
else
    popm_showCellType_h.String = data.settings.displayCellOptions{3};
    popm_kymo_alignment_h.String = data.settings.algnmentOptions{3};
end

% Calculate maximum height of panel
% Loop over tabs
tabs_h = data.ui.fb(2).g(1).params.h.Children.Children(1).Children;

maxSizeAll = zeros(numel(tabs_h), 1);
for i = 1:numel(tabs_h)
    elements = tabs_h(i).Children.Children;
    maxSize = zeros(numel(elements), 1);
    
    for j = 1:numel(elements)
        switch elements(j).Type
            case 'uicontainer'
                if numel(elements(j).Children) == 2
                    if strcmp(elements(j).Children(1).Visible, 'on')
                        maxSize(j) = elements(j).Children(1).Position(4) + sum(elements(j).Children(2).Heights) + 10;
                    end
                else
                    if strcmp(elements(j).Children(1).Children(1).Visible, 'on')
                        maxSize(j) = sum(elements(j).Children(1).Heights) + 10;
                    end
                end
            case 'uicontrol'
                maxSize(j) = elements(j).Position(4);
        end
    end
    maxSizeAll(i) = sum(maxSize);
end

data.ui.fb(2).g(1).params.h.Heights = max(maxSizeAll)+10;

setUIData(data.mainFigure, data);


