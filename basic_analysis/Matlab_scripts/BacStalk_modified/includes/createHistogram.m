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

function createHistogram(src, ~)

data = getUIData(src);

measurement_h = findobj(data.mainFigure, 'Tag', 'popm_histo_measurement');
spacing_h = findobj(data.mainFigure, 'Tag', 'ed_histo_spacing');

fields = measurement_h.String(measurement_h.Value);
spacing = str2num(spacing_h.String);

if isempty(spacing)
    msgbox('Bin-input has to be either (i) an integer defining the number of bins or (ii) three numbers in the format [start:spacing:end] or (iii) an array of numbers for the bin-values.', 'Please note', 'help', 'modal');
    spacing_h.String = '10';
    return;
end

toggleBusyPointer(data, 1)

indexes = getDataIndices(data);

frames = cell2mat(data.resultsTable(indexes,1));
cellIDs = cell2mat(data.resultsTable(indexes,2));

[compiledData, unit] = compileDataSimple(src, [], frames, cellIDs, fields);

if numel(spacing) > 1
    x = spacing; 
    counts = histc(compiledData, x);
else
    [counts, x] = hist(compiledData, spacing);
end

h = figure('Name', sprintf('Histogram: %s', fields{1}));
h = addIcon(h);
h_ax = axes('Parent', h);

bar(h_ax, x, counts);

xlabel(h_ax, [strrep(fields{1}, '_', ''), unit{1}]);
ylabel(h_ax, 'Counts');

box(h_ax, 'on');
toggleBusyPointer(data, 0)

