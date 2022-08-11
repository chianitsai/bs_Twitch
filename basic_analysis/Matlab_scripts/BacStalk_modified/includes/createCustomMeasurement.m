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


function createCustomMeasurement(src, ~, mainGUI, measurementFig, defaultField, defaultFormula)
data = getUIData(mainGUI);

if nargin < 5
    defaultField = 'BoxArea';
    defaultFormula = {'{CellLength} * ','{CellWidth}'};
end

fig_h = ancestor(src,'figure','toplevel');

enableDisableFig(fig_h, false);

h = figure('Name', 'Add custom measurement field', 'MenuBar', 'None');
addIcon(h);

h.Position(3) = 300;
h.Position(4) = 300;

tabColor = [0.7490 0.902 1];

sc1 = uix.ScrollingPanel('Parent', h);
div = uix.HBox('Parent', sc1, 'Padding', 5);

p1 = uix.BoxPanel('Parent', div, 'Title', 'Add custom measurement', 'Padding', 5, ...
    'TitleColor', tabColor, 'ForegroundColor', 'black', 'HelpFcn', {@openHelp, 'usage/analysis.html#custom-measurement-fields'});

box = uix.VBox('Parent', p1, 'Spacing', 10);
text_description1 = uicontrol('Style', 'text', 'Parent', box, ...
    'String', 'Create custom measurement based on formula:', 'HorizontalAlignment', 'left');

box2 = uix.HBox('Parent', box);
text_description2 = uicontrol('Style', 'text', 'Parent', box2, ...
    'String', 'Field name', 'HorizontalAlignment', 'left');
jh = findjobj(text_description2);
jh.setVerticalAlignment(javax.swing.JLabel.CENTER)
ed_fieldName = uicontrol('Style', 'edit', 'String', defaultField, 'Parent', box2,...
    'HorizontalAlignment', 'left', 'Tag', 'ed_fieldName', 'Callback', {@custom_measurements_checkField, mainGUI});
box2.Widths = [80 -1];

box3 = uix.HBox('Parent', box);

ed_formula = uicontrol('Style', 'edit', 'String', defaultFormula, 'Parent', box3,...
    'HorizontalAlignment', 'left', 'FontName', 'FixedWidth', 'Tag', 'ed_formula', 'Min', 1, 'Max', 4);

bb1 = uix.VButtonBox('Parent', box3, 'Padding', 5, 'VerticalAlignment', 'top');
pb_addField = uicontrol('Style', 'pushbutton', 'String', 'Add measurement', 'Parent', bb1, 'Callback', {@custom_measurements_addField, mainGUI});
pb_testFormula = uicontrol('Style', 'pushbutton', 'String', 'Test formula', 'Parent', bb1, 'Callback', {@custom_measurements_testFormula, mainGUI});
bb1.Spacing = 10;
bb1.ButtonSize = [120 20];

box3.Widths = [-1 120];


bb2 = uix.HButtonBox('Parent', box, 'Padding', 5);
pb_OK = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Parent', bb2, ...
    'Callback', {@custom_measurements_OK, mainGUI, measurementFig});
pb_cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Parent', bb2, 'Callback', @custom_measurements_cancel);
bb2.Spacing = 10;
bb2.ButtonSize = [100 20];

box.Heights = [28 28 -1 40];

uiwait(h)
enableDisableFig(fig_h, true);

%%
function custom_measurements_OK(src, ~, mainGUI, measurementFig)
fig_h = ancestor(src,'figure','toplevel');

ed_fieldName_h = findobj(fig_h, 'Tag', 'ed_fieldName');

if custom_measurements_checkField(ed_fieldName_h, [], mainGUI)
    return;
end

if ~custom_measurements_testFormula(src, [], mainGUI)
    return;
end

ed_formula_h = findobj(fig_h, 'Tag', 'ed_formula');
formulaRaw = [ed_formula_h.String{:}];
fields = extractBetween(formulaRaw,'{','}');
formula = formulaRaw;
if ~isempty(fields)
    for i = 1:numel(fields)
        formula = strrep(formula, ['{', fields{i}, '}'], sprintf('stats(i).%s', fields{i}));
    end
else
    formula = formulaRaw;
end

fieldName = ['Custom_', ed_fieldName_h.String];

data = getUIData(mainGUI);

lb_measurements_h = findobj(measurementFig, 'Tag', 'lb_measurements');


if isfield(data.settings, 'customMeasurementFieldNames')
    idx = find(strcmp({data.settings.customMeasurementFieldNames.fieldName}, fieldName));
    
    if isempty(idx)
       idx = numel(data.settings.customMeasurementFieldNames)+1;
       lb_measurements_h.String = [lb_measurements_h.String; fieldName];
    end
    data.settings.customMeasurementFieldNames(idx).fieldName = fieldName;
    data.settings.customMeasurementFieldNames(idx).formula = formula;
    data.settings.customMeasurementFieldNames(idx).formulaRaw = formulaRaw;
else
    data.settings.customMeasurementFieldNames.fieldName = fieldName;
    data.settings.customMeasurementFieldNames.formula = formula;
    data.settings.customMeasurementFieldNames.formulaRaw = formulaRaw;
    lb_measurements_h.String = [lb_measurements_h.String; fieldName];
end

setUIData(data.mainFigure, data);

populateMeasurementSelectionElements(mainGUI, []);

delete(fig_h);

%%
function custom_measurements_cancel(src, ~)
delete(ancestor(src,'figure','toplevel'))

%%
function custom_measurements_addField(src, ~, mainGUI)
fig_h = ancestor(src,'figure','toplevel');
data = getUIData(mainGUI);
measurementFields = returnMeasurementFields(data, 'direct');

enableDisableFig(fig_h, false);
[s,v] = listdlg('Name', 'Measurement fields',...
                'PromptString','Select measurement:',...
                'SelectionMode','single',...
                'ListString',measurementFields,...
                'InitialValue', 1,...
                'ListSize', [400 500]);
enableDisableFig(fig_h, true);

if v
    ed_formula_h = findobj(fig_h, 'Tag', 'ed_formula');
    ed_formula_h.String = textwrap(ed_formula_h,{[[ed_formula_h.String{:}], ' {', measurementFields{s}, '}']});
end
 
%%
function corrected = custom_measurements_checkField(src, ~, mainGUI)
src.String = matlab.lang.makeValidName(src.String);
data = getUIData(mainGUI);
valid = false;
corrected = false;

while ~valid
    valid = true;
    measurementFields = returnMeasurementFields(data, 'all');
    if ~isempty(intersect(['Custom_', src.String], measurementFields))
        answer = questdlg(sprintf('Measurement field "%s" already in use! Overwrite?', src.String), ...
            'Measurement field already in use', ...
            'Yes', 'No', 'Yes');
        
        switch answer
            case 'Yes'
                valid = true;
            case 'No'
                valid = false;
                corrected = true;
        end
        
    end
end

%%
function valid = custom_measurements_testFormula(src, ~, mainGUI)
valid = true;
fig_h = ancestor(src,'figure','toplevel');
ed_formula_h = findobj(fig_h, 'Tag', 'ed_formula');
formula = [ed_formula_h.String{:}];
fields = extractBetween(formula,'{','}');

for i = 1:numel(fields)
    formula = strrep(formula, ['{', fields{i}, '}'], sprintf('stats(i).%s', fields{i}));
end
    
data = getUIData(mainGUI);

for j = 1:numel(data.frames)
    if ~isempty(data.frames(j).cells)
        try
            data.frames(j).cells(1).Stats
            %stats = prepareStatsData(data.frames(j).cells(1).Stats, data);
            stats = data.frames(j).cells(1).Stats;
            eval([formula, ';'])
            uiwait(msgbox('Formula does not contain any errors.', 'Formula accepted', 'help', 'modal'))
            break;
        catch err
            msgbox(err.message, 'Error in formula', 'error', 'modal')
            valid = false;
            break;
        end
    end
end
%%