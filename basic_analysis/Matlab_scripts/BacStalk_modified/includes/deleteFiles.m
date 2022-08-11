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

function deleteFiles(src, ~)

data = getUIData(src);

lb_files = findobj(data.mainFigure, 'tag', 'lb_files');

if numel(lb_files.String) > 0
    selectedFiles = lb_files.Value;
    
    lb_files.String(selectedFiles) = [];
    
    lb_files.Max = numel(lb_files.String);
    
    if selectedFiles(1) > 1
        lb_files.Value = selectedFiles(1)-1;
    else
        lb_files.Value = 1;
    end
end