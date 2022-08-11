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

function valid = checkInput(src, ~)

input = str2double(src.String);
src.String = num2str(input);

if ~isnumeric(input) || numel(input)>1  || isnan(input) || isinf(input)
    msgbox(sprintf('Input "%s" has to be numeric!', src.Tag), 'Wrong input', 'warn', 'modal');
    src.String = src.UserData{1};
    valid = false;
else
    valid = true;
    pause(0.1)

    % Check cell size
    if strcmpi(src.Tag, 'cellsize')
        data = getUIData(src);
        im_h = findobj(data.axes.main, 'Type', 'Image');
        ROI_inner = [[0 0] + 5*input [size(im_h.CData, 2) size(im_h.CData, 1)]-2*5*input];
        
        if ROI_inner(3) < 0 || ROI_inner(4) < 0
            minCellSize = floor(min([size(im_h.CData, 2) size(im_h.CData, 1)])/10);
            uiwait(msgbox({'The image is not compatible with the entered cell size (the dashed rectangle does not fit)!', 'Either provide a larger image (in pixels) or reduce the cell size.', ...
                sprintf('The maximum allowed cell size for this image is %d.', minCellSize)}, 'Error', 'error', 'modal'));
            src.String = num2str(minCellSize);
            input = minCellSize;
            valid = false;
        end
        
    end
    
    if input < src.UserData{2}(1)
        if strcmp(src.UserData{3}, 'integer')
            uiwait(msgbox(sprintf('Input "%s" has to be larger than or equal to %d!', src.Tag, src.UserData{2}(1)), 'Input too small', 'warn', 'modal'));
        else
            uiwait(msgbox(sprintf('Input "%s" has to be larger than or equal to %.1f!', src.Tag, src.UserData{2}(1)), 'Input too small', 'warn', 'modal'));
        end
        src.String = src.UserData{2}(1);
        valid = false;
    end
    
    if input > src.UserData{2}(2)
        if strcmp(src.UserData{3}, 'integer')
            uiwait(msgbox(sprintf('Input "%s" has to be smaller than or equal to %d!', src.Tag, src.UserData{2}(2)), 'Input too large', 'warn', 'modal'));
        else
            uiwait(msgbox(sprintf('Input "%s" has to be smaller than or equal to %.1f!', src.Tag, src.UserData{2}(2)), 'Input too large', 'warn', 'modal'));
        end
        src.String = src.UserData{2}(2);
        valid = false;
    end
    
    if strcmp(src.UserData{3}, 'integer') && round(input) ~= input
        uiwait(msgbox(sprintf('Input has "%s" to be an integer number between %d and %d!', src.Tag, src.UserData{2}(1), src.UserData{2}(2)), 'Input not integer', 'warn', 'modal'));
        src.String = round(input);
        checkInput(src, []);
        valid = false;
    end
end

