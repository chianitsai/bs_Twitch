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

function showDeletionComment(h_ax, SingleCellStats)

if ~isempty(SingleCellStats.Comment)
    if strcmp(SingleCellStats.Comment(1:3), '(?)')
        commentStr = sprintf('This cell might not be segmented properly because:\n\\color{orange}%s\n\\color{black}(Click to close)', SingleCellStats.Comment(4:end));
    else
        if SingleCellStats.CellDeleted
            commentStr = sprintf('This cell was deleted because:\n\\color{red}%s\n\\color{black}(Click to close)', SingleCellStats.Comment);
        else
            commentStr = sprintf('%s\n\\rm(Click to close)', SingleCellStats.Comment);
        end
    end
else
    if SingleCellStats.CellDeleted
        commentStr =  sprintf('This cell was deleted by the user.\n(Click to close)');
    else
        commentStr =  sprintf('\\sl This cell seems to be happy.\n\\rm(Click to close)');
    end
end

text(SingleCellStats.CellOutlineCoordinates(round(end/2),2), SingleCellStats.CellOutlineCoordinates(round(end/2),1),...
    commentStr, 'Parent', h_ax, 'BackgroundColor', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @deleteComment);
