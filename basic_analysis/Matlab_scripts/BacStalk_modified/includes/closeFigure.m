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

function closeFigure(src, ~)

data = getUIData(src);

% if isfield(data, 'frames')
%     choice = questdlg('Save data before closing?',...
%         'Save data?', ...
%         'Yes','No','Cancel', 'Cancel');
%     switch choice
%         case 'Yes'
%             
%             saveData(src, [])
%         case 'No'
%             % Do nothing
%         case 'Cancel'
%             return;
%     end
% end
'close'
delete(data.mainFigure);

warning off;
delete(timerfindall('Tag', 'timer_progressBar'));
delete(timerfindall('Tag', 'timer_busy'));
warning on;