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

function heights = generateParameters(parent, parameters)

heights = [];
for i = 1:size(parameters,1)
    g_parent = uix.Grid('Parent', parent, 'Spacing', 0, 'Padding', 0);
    
    g = uix.Grid('Parent', g_parent, 'Spacing', 5);
    
    uicontrol('Parent', g, 'Style', 'Text', 'String', parameters{i, 1}, ...
        'HorizontalAlignment', 'left')
    
    switch parameters{i, 5}
        case 'Edit'
            switch parameters{i, 7}
                case 'integer'
                    tooltipStr = sprintf('%s: enter an integer number between %d and %d', parameters{i, 1}, parameters{i, 6}(1), parameters{i, 6}(2));
                case 'float'
                    tooltipStr = sprintf('%s: enter a floating point number between %.1f and %.1f', parameters{i, 1}, parameters{i, 6}(1), parameters{i, 6}(2));
            end
            
            h = uicontrol('Parent', g, 'Style', 'Edit', 'String', parameters{i, 2}, ...
                'Tag', matlab.lang.makeValidName(parameters{i, 1}), 'Callback', @checkInput, ...
                'UserData', {parameters{i, 2}, parameters{i, 6}, parameters{i, 7}}, ...
                'TooltipString', tooltipStr);
            
        case 'Checkbox'
            uicontrol('Parent', g, 'Style', 'Checkbox', 'String', '', 'Value', parameters{i, 2}, ...
                'Tag', matlab.lang.makeValidName(parameters{i, 1}), ...
                'TooltipString', sprintf('Click to turn "%s" on or off', parameters{i, 1}));
            
        case 'Color'
            h = uicontrol('Parent', g, 'Style', 'Pushbutton', 'String', '', ...
                'Tag', matlab.lang.makeValidName(parameters{i, 1}), 'UserData', parameters{i, 2});
            
            % If userdata is color change background color of edit
            c = parameters{i, 2};
            if numel(c) == 3 && max(c) <= 1 && min(c) >= 0
                h.BackgroundColor = c;
                h.Callback = @changeColor;
                h.TooltipString = sprintf('Click to pick a %s', parameters{i, 1});
            end
            
        case 'Popupmenu'
            uicontrol('Parent', g, 'Style', 'Popupmenu', 'String', parameters{i, 2}, 'Value', parameters{i, 3}, ...
                'Tag', matlab.lang.makeValidName(parameters{i, 1}), ...
                'TooltipString', sprintf('Select "%s"', parameters{i, 1}));
    
    end
    
    % Add unit
    if ~strcmp(parameters{i, 5}, 'Popupmenu')
        uicontrol('Parent', g, 'Style', 'Text', 'String', parameters{i, 3}, ...
            'HorizontalAlignment', 'left')
    end
    
    if numel(g.Children) == 3
        set(g, 'Widths', [120 40 40], 'Heights', [20]);
    else
        set(g, 'Widths', [120 110], 'Heights', [20]);
    end
    
    heights(end+1) = 20;
    
    if ~isempty(parameters{i, 4})
        uicontrol('Parent', g_parent, 'Style', 'Text', 'String', parameters{i, 4}, ...
            'HorizontalAlignment', 'left', 'FontAngle', 'italic')
        heights(end) = 60;
        set(g_parent, 'Widths', -1, 'Heights', [20 40]);
    else
    
        set(g_parent, 'Widths', -1, 'Heights', 20);
    end
end