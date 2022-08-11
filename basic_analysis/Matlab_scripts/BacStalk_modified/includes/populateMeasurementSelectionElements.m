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


function [fields, filterFields] = populateMeasurementSelectionElements(src, ~)

data = getUIData(src);

% Histogram & Scatterplot
try
    measurements = {};
    filterFields = {};
    
    cells = data.frames(find(cellfun(@(x) ~isempty(x), {data.frames.cells}), 1)).cells;
    singleCellStats = cells.Stats(1);
    singleCellStats.Frame = 1;
    fields = union(fieldnames(singleCellStats), {'Frame'});
    fields = setdiff(fields, {'CellID', 'Comment', 'ConnectedWith'});
    
    
    
    for i = 1:numel(fields)
        fieldData = singleCellStats.(fields{i});
        if (isnumeric(fieldData) || islogical(fieldData)) && numel(fieldData) <= 1 && ~isempty(fieldData) && ~strcmp(fields{i}(end-2:end), 'Idx') && ~strcmp(fields{i}(end-2:end), 'Idx') && size(fieldData, 2) == 1 
            measurements{end+1} = fields{i};
        end
        
        if (isnumeric(fieldData) || islogical(fieldData)) && ~strcmp(fields{i}(end-2:end), 'Idx') && size(fieldData, 2) == 1 
            filterFields{end+1} = fields{i};
        end
    end

    measurements = union(measurements, {'CellStalkLength', 'CellStalkBudLength', 'StalkBudLength', 'BudLength', 'BudArea', 'StalkLength'});
    filterFields = union(filterFields, {'CellStalkLength', 'CellStalkBudLength', 'StalkBudLength', 'BudLength', 'BudArea', 'StalkLength'});
    
    filterFields = sort(filterFields);
    
    % Get formula-fields
    if isfield(data.settings, 'customMeasurementFieldNames')
        measurements = [measurements {data.settings.customMeasurementFieldNames.fieldName}];
        filterFields = [filterFields {data.settings.customMeasurementFieldNames.fieldName}];
    end
    
    popm_h = [findobj(data.mainFigure, '-regexp', 'Tag', 'popm_scatter_measurement');...
        findobj(data.mainFigure, 'Tag', 'popm_histo_measurement')];
    for i = 1:numel(popm_h)
        popm_h(i).String = measurements;
        popm_h(i).Value = 1;
    end
   
    %% Update filter fields
    
    filterCellField_h = findobj(data.mainFigure, 'Tag', 'popm_filterCellField');
    if numel(filterCellField_h.String) ~= numel(filterFields)
        filterCellField_h.String = filterFields;
        filterCellField_h.Value = 1;
    end

catch
    fields = [];
    warning('Measurement fields could not be updated!');
    msgbox('Measurement fields could not be updated!', 'Error in formula', 'error', 'modal')
end