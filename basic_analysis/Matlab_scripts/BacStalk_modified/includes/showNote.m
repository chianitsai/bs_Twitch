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

function showNote(h_ax, coords, note, color)

if nargin == 3
    color = 'black';
end

t_h = text(coords(:,1), coords(:,2), ...
    sprintf('\\color{%s}%s', color, note), 'Parent', h_ax, 'BackgroundColor', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @deleteComment);


t = timer('ExecutionMode', 'singleShot', 'StartDelay', 1.5, 'TimerFcn', {@deleteComment, t_h}, 'Tag', 'timer_comment');
start(t)

