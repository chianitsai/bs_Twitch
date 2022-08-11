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

function selectMeasurements(src, ~)

data = getUIData(src);

measurementFields = returnMeasurementFields(data, 'all');

% Determine selected fields
[~, selectedFields] = intersect(measurementFields, data.settings.measurementsFields);

enableDisableFig(data.mainFigure, false);

%% Create interface for measurement selection
h = figure('Name', 'Measurement fields', 'MenuBar', 'None');
h.Position(1:2) = h.Position(1:2)-200;
h.Position(3:4) = h.Position(3:4)+200;
addIcon(h);

tabColor = [0.7490 0.902 1];

sc1 = uix.ScrollingPanel('Parent', h);
div = uix.VBox('Parent', sc1, 'Padding', 5);
% Left side
p1 = uix.BoxPanel('Parent', div, 'Title', 'Select measurements', 'Padding', 5, ...
    'TitleColor', tabColor, 'ForegroundColor', 'black', 'HelpFcn', {@openHelp, 'usage/analysis.html#measurement-fields'});
box = uix.VBox('Parent', p1);
box_list = uix.HBox('Parent', box);
box_list_v = uix.VBox('Parent', box_list);

text_description1 = uicontrol('Style', 'text', 'Parent', box_list_v, ...
    'String', 'Select measurements fields (hold "Ctr" for multi-selection):', 'HorizontalAlignment', 'left');
lb_measurements = uicontrol('Style', 'listbox', 'Parent', box_list_v, 'Tag', 'lb_measurements', ...
    'String', measurementFields, 'Value', selectedFields, 'Min', 1, 'Max', numel(measurementFields), ...
    'UserData', selectedFields, 'Callback', {@measurements_clickMeasurementsList, src});

%uix.Empty('Parent', box_list)
bb1 = uix.VButtonBox('Parent', box_list, 'Padding', 5, 'VerticalAlignment', 'top');
uix.Empty('Parent', bb1);
pb_selectAll = uicontrol('Style', 'pushbutton', 'String', 'Select all', 'Parent', bb1, ...
    'Callback', {@measurements_selection, lb_measurements, 'selectAll'});
pb_deselectAll = uicontrol('Style', 'pushbutton', 'String', 'De-select all', 'Parent', bb1,...
    'Callback', {@measurements_selection, lb_measurements, 'deselectAll'});
pb_reset = uicontrol('Style', 'pushbutton', 'String', 'Reset', 'Parent', bb1, ...
    'Callback', {@measurements_selection, lb_measurements, 'reset'});
uix.Empty('Parent', bb1);
pb_addCustom = uicontrol('Style', 'pushbutton', 'String', 'Add custom', 'Parent', bb1, 'Callback', {@createCustomMeasurement, src, h});
pb_modifyCustom = uicontrol('Style', 'pushbutton', 'String', 'Modify', 'Parent', bb1, 'Callback', {@measurements_modifyCustomMeasurement, src, h}, ...
    'Enable', 'off', 'Tag', 'pb_modifyCustom');
pb_deleteCustom = uicontrol('Style', 'pushbutton', 'String', 'Delete', 'Parent', bb1, 'Callback', {@measurements_deleteCustomMeasurement, src}, ...
    'Enable', 'off', 'Tag', 'pb_deleteCustom');

bb1.Spacing = 10;
bb1.ButtonSize = [80 20];

box_list.Widths = [-1 90];
box_list_v.Heights = [28 -1];

% Bottom
p2 = uix.BoxPanel('Parent', div, 'Title', 'Description', 'Padding', 10, ...
    'TitleColor', tabColor, 'ForegroundColor', 'black', 'HelpFcn', {@openHelp, 'usage/analysis.html#cell-table'});
box2 = uix.VBox('Parent', p2);
text_description_title = uicontrol('Style', 'text', 'Parent', box2, ...
    'String', {''}, 'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'Tag', 'txt_measurement_title');
text_description_body = uicontrol('Style', 'text', 'Parent', box2, ...
    'String', {'Please click on a measurement'}, 'HorizontalAlignment', 'left', 'FontAngle', 'italic', 'Tag', 'txt_measurement_description');


bb2 = uix.HButtonBox('Parent', div, 'Padding', 5);
pb_OK = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Parent', bb2, ...
    'Callback', {@measurements_OK, src});
pb_cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Parent', bb2, 'Callback', @measurements_cancel);
bb2.Spacing = 10;
bb2.ButtonSize = [100 20];

box2.Heights = [20 -1];

div.Heights = [-1 100 35];
uiwait(h)
enableDisableFig(data.mainFigure, true);


%%
function measurements_OK(src, ~, mainGUI)
data = getUIData(mainGUI);

fig_h = ancestor(src,'figure','toplevel');
lb_measurements_h = findobj(fig_h, 'Tag', 'lb_measurements');

s = lb_measurements_h.Value;

data.settings.measurementsFields = {'Frame', 'CellID', lb_measurements_h.String{s}};
data = createAnalysisTable(data);
setUIData(data.mainFigure, data);
delete(fig_h);

%%
function measurements_cancel(src, ~)
delete(ancestor(src,'figure','toplevel'))

%%
function measurements_deleteCustomMeasurement(src, ~, mainGUI)
data = getUIData(mainGUI);

fig_h = ancestor(src,'figure','toplevel');
lb_measurements_h = findobj(fig_h, 'Tag', 'lb_measurements');

field = lb_measurements_h.String{lb_measurements_h.Value};
lb_measurements_h.String(lb_measurements_h.Value) = [];
lb_measurements_h.Value = [];
lb_measurements_h.Max = numel(lb_measurements_h.String);

pb_delete_h = findobj(fig_h, 'Tag', 'pb_deleteCustom');
pb_delete_h.Enable = 'Off';
pb_modify_h = findobj(fig_h, 'Tag', 'pb_modifyCustom');
pb_modify_h.Enable = 'Off';

data.settings.customMeasurementFieldNames(strcmp({data.settings.customMeasurementFieldNames.fieldName}, field)) = [];

if ~numel(data.settings.customMeasurementFieldNames)
    data.settings = rmfield(data.settings, 'customMeasurementFieldNames');
end
setUIData(data.mainFigure, data);

%%
function measurements_modifyCustomMeasurement(src, ~, mainGUI, measurementFig)
data = getUIData(mainGUI);
lb_measurements_h = findobj(measurementFig, 'Tag', 'lb_measurements');
field = lb_measurements_h.String{lb_measurements_h.Value};
formula = {data.settings.customMeasurementFieldNames(find(strcmp({data.settings.customMeasurementFieldNames.fieldName}, field))).formulaRaw};
createCustomMeasurement(src, [], mainGUI, measurementFig, strrep(field, 'Custom_', ''), formula)

%%
function measurements_selection(~, ~, lb_measurements, type)

switch type
    case 'selectAll'
        lb_measurements.Value = 1:numel(lb_measurements.String);
    case 'deselectAll'
        lb_measurements.Value = [];
    case 'reset'
        lb_measurements.Value = lb_measurements.UserData;
end

%%
function measurements_clickMeasurementsList(src, ~, mainGUI)
data = getUIData(mainGUI);
fig_h = ancestor(src,'figure','toplevel');
pb_delete_h = findobj(fig_h, 'Tag', 'pb_deleteCustom');
pb_modify_h = findobj(fig_h, 'Tag', 'pb_modifyCustom');
pb_delete_h.Enable = 'Off';
pb_modify_h.Enable = 'Off';
txt_measurement_description_h = findobj(fig_h, 'Tag', 'txt_measurement_description');
txt_measurement_title_h = findobj(fig_h, 'Tag', 'txt_measurement_title');
txt_measurement_title_h.String = src.String{src.Value};
description = {'No description available'};

if numel(src.Value) == 1
    fieldName = src.String{src.Value};
    
    switch src.String{src.Value}
        
        case 'Area'
            description = {'Area of the cell body (excluding stalk) in square microns.'};
            
        case 'Orientation'
            description = {'Angle with x-axis in which the cells lies in degrees.'};
            
        case 'CellLength'
            description = {'Length of the cell body (excluding stalk) in microns'};
            
        case 'CellWidth'
            description = {'Maximum width of the cell body in microns.'};
            
        case 'Stalk'
            description = {'Cell has stalk: yes or no.'};
            
        case 'StalkLength'
            description = {'Stalk length in microns.'};
            
        case 'ConnectedWith'
            description = {'CellID of bud in case the cell is connected to a bud.'};
            
        case 'Bud'
            description = {'Cell is bud: yes or no.'};
            
        case 'Time'
            description = {'Time metadata information extracted from filenames.'};
            
        case 'Position'
            description = {'Position metadata information extracted from filenames.'};
            
        case 'TrackID'
            description = {'Unique index per trajectory, stays the same for a cell through time.'};
            
        case 'Parent'
            description = {'CellID of parent cell in previous frame, in case the cell has divided in the meantime.'};
            
        case 'Grandparent'
            description = {'CellID of parent cell in second to last frame, in case the cell has divided in the meantime.'};
            
        case 'BudArea'
            description = {'Area of associated bud (if existing) in square microns.'};
            
        case 'BudLength'
            description = {'Length of associated bud (if existing) in microns.'};
            
        case 'CellStalkLength'
            description = {'Length of cell + associated stalk (if existing) in microns.'};
            
        case 'CellStalkBudLength'
            description = {'Length of cell + associated stalk and bud (if existing) in microns.'};
            
        case 'StalkBudLength'
            description = {'Length of associated stalk and bud (if existing) in microns.'};
            
        case 'CellDeleted'
            description = {'Cell was deleted (either automatically during segmentation or manually by user): yes or no.'};
            
        case 'Comment'
            description = {'If a cell was automatically marked as CellDeleted=1, the reason for this is stored here.'};
            
        case 'StalkTouchesEdge'
            description = {'This field indicates if the cell touched the edge of the cell segmentation field or the specified ROI.'};
            
        otherwise
            
            % Check for custom fields
            if numel(fieldName) > 6
                if strcmp(fieldName(1:6), 'Custom')
                    pb_delete_h.Enable = 'On';
                    pb_modify_h.Enable = 'On';
                    formula = data.settings.customMeasurementFieldNames(find(strcmp({data.settings.customMeasurementFieldNames.fieldName}, src.String{src.Value}))).formulaRaw;
                    description = {'Custom measurement field based on the formula:', '', formula};
                end
            end
            
            % Check for brightest focus related fields
            if ~isempty(strfind(fieldName, 'BrightestFocus'))
                typeIdx = strfind(fieldName, '_A_');
                if isempty(typeIdx)
                    typeIdx = strfind(fieldName, '_B_');
                end
                
                channel = fieldName(16:typeIdx-1);
                description = {sprintf('Channel %s: ', channel)};
                
                if ~isempty(strfind(fieldName, 'Distance'))
                    if ~isempty(strfind(fieldName, 'DistanceToCellCenter'))
                        description = {[description{1}, 'Distance to first intensity maximum inside each cell as measured from cell center']};
                    else
                        description = {[description{1}, 'Distance to first intensity maximum inside each cell as measured from cell pole']};
                    end
                else
                    description = {[description{1}, 'Intensity of first intensity maximum (averaged over the 3x3 neighboring pixels)']};
                end
                if ~isempty(strfind(fieldName, '_A_'))
                    description = {[description{1}, '']};
                else
                    description = {[description{1}, ', takes stalk and bud into account']};
                end
                
                
                if ~isempty(strfind(fieldName, 'Distance'))
                    description = {[description{1}, ', in microns.']};
                else
                    description = {[description{1}, ', in intensity units of the image.']};
                end
            end
            
            % Check for intensity related fields
            if ~isempty(strfind(fieldName, 'MeanCellIntensity'))
                channel = fieldName(19:end);
                description = {sprintf('Channel %s: Average intensity per cell in intensity units of the image.', channel)};
            end
            
            if ~isempty(strfind(fieldName, 'MedianCellIntensity'))
                channel = fieldName(21:end);
                description = {sprintf('Channel %s: Median intensity per cell in intensity units of the image.', channel)};
            end
            
            if ~isempty(strfind(fieldName, 'MinCellIntensity'))
                channel = fieldName(18:end);
                description = {sprintf('Channel %s: Minimum intensity per cell in intensity units of the image.', channel)};
            end
            
            if ~isempty(strfind(fieldName, 'MaxCellIntensity'))
                channel = fieldName(18:end);
                description = {sprintf('Channel %s: Maximum intensity per cell in intensity units of the image.', channel)};
            end
            
            % Filename related fields
            if ~isempty(strfind(fieldName, 'Filename'))
                channel = fieldName(10:end);
                description = {sprintf('Channel %s: Filename of the corrensponding image.', channel)};
            end
    end
end

txt_measurement_description_h.String = description;


%%