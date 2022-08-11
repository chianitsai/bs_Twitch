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

function createScreenshot(src, ~, type)
data = getUIData(src);

% Load previous directory
if isdeployed
    if exist('directory.mat','file')
        load('directory.mat');
    else
        directory = '';
    end
else
    if exist(fullfile(data.guiPath, 'includes', 'directory.mat'),'file')
        load('directory.mat');
    else
        directory = data.guiPath;
    end
end

switch type
    case 'screenshot'
        slider_h = findobj(data.mainFigure, 'Tag', 'slider_im');
        range = round(slider_h.Value);
        [filenameFull, directory] = uiputfile({'*.png'; '*.jpg'; '*.eps'}, 'Save screenshot', fullfile(directory, 'screenshot.png'));
    case 'movie'
        range = 1:numel(data.frames);
        profiles = VideoWriter.getProfiles();
        
        videoTypes = {'*.png', 'Image file sequence'; '*.jpg', 'Image file sequence'; '*.eps', 'Image file sequence'};
        videoTypes = [videoTypes; [cellfun(@(x) ['*',x{1}], {profiles.FileExtensions}, 'UniformOutput', false)' {profiles.Name}']];
        [filenameFull, directory, extIdx] = uiputfile(videoTypes, 'Save image sequence', fullfile(directory, 'movie.png'));
end

if directory
    
    filenameSeries = filenameFull;
    [~, filename, ext] = fileparts(filenameFull);
    
    if strcmp(type, 'movie') && data.settings.isTimeseries
        answer = questdlg('Add time label?', ...
            'Add label?', ...
            'Yes','No','Yes');
        
        switch answer
            case 'Yes'
                addTimeLabel = true;
                prompt = {'Font Size', 'Scaling', 'Unit'};
                title = 'Label properties';
                dims = [1 35];
                definput = {'14','1','frame'};
                opts = struct('Resize', 'off', 'WindowStyle', 'modal', 'Interpreter', 'none');
                labelProps = inputdlg(prompt,title,dims,definput, opts);
                text_color_h = findobj(data.mainFigure, 'tag', 'TextColor');
                text_color = text_color_h.UserData;
                
            case 'No'
                addTimeLabel = false;
        end
    else
        addTimeLabel = false;
    end
    
    if ~(strcmp(ext, '.png') || strcmp(ext, '.jpg') || strcmp(ext, '.eps')) % Initialize movie
        F(numel(data.frames)) = struct('cdata',[],'colormap',[]);
        makeMovie = true;

        prompt = {'Frame rate (per s):','Quality (%):'};
        title = 'Movie properties';
        dims = [1 35];
        definput = {'10','95'};
        opts = struct('Resize', 'off', 'WindowStyle', 'modal', 'Interpreter', 'none');
        movieProps = inputdlg(prompt,title,dims,definput, opts);
        if isempty(movieProps)
            return;
        end
    else
        makeMovie = false;
    end
    
    
    toggleBusyPointer(data, 1)
    
    if numel(range) == 1
        displayStatus(src, [], 'Exporting screenshot')
    else
        displayStatus(src, [], 'Exporting movie frames')
    end
    
    warning off;
    delete(timerfindall('Tag', 'progress_bar'));
    warning on;
    
    cancelButton = findobj(data.mainFigure, 'Tag', 'pb_cancel');
    cancelButton.Enable = 'on';
    
    ax_h_progress = data.axes.progress;
    guiPath = data.guiPath;
    
    hbar = parfor_progressbar(numel(range),ax_h_progress);
    
    width = diff(data.axes.main.XLim);
    height = diff(data.axes.main.YLim);
    
    h = figure('Name', sprintf('Saving %s, please wait...', type), 'Visible', 'off', 'Units', 'centimeters',...
        'Position', [0 0 width/height*20 20]);
    
    h = addIcon(h);
    
    removeLabelDlg = true;
    for i = 1:numel(range)
        if iscancelled(guiPath)
            close(hbar);
            updateWaitbar(data.axes.progress, 0)
            displayStatus(src, [], '')
            delete(h);
            resetCancelButton(data);
            toggleBusyPointer(data, 0)
            return;
        end
        
        try
            
            frame = range(i);
            
            if numel(range) > 1
                displayImage(src, [], frame)
                filenameSeries = sprintf('%s_%05d', filename, i);
                toggleBusyPointer(data, 1)
            end
            
            delete(h.Children);
            copyobj(data.axes.main, h);
            
            % Delete crop rectangle
            delete(findobj(h.Children, 'Type', 'Rectangle'));
            
            % Delete endpoint of scalebar
            try
                delete(findobj(h.Children, 'Tag', 'end point 1'))
                delete(findobj(h.Children, 'Tag', 'end point 2'))
                
                if removeLabelDlg
                    answerLabel = questdlg('Do you want to remove the label of the scale bar in the screenshot/movie?', ...
                        'Remove label?', ...
                        'Yes','No','Yes');
                    removeLabelDlg = false;
                end
                
                switch answerLabel
                    case 'Yes'
                        delete(findobj(h.Children, 'Tag', 'scalebar'));
                    case 'No'
                end
            end
           
            if addTimeLabel
                try
                    fontSize = str2double(labelProps{1});
                catch
                    msgbox('Invalid font size!', 'Warning', 'warn', 'modal')
                    fontSize = 12;
                end
                
                try
                    timeScaling = str2double(labelProps{2});
                catch
                    msgbox('Invalid time scaling!', 'Warning', 'warn', 'modal')
                    timeScaling = 1;
                end
                
                if strcmp(labelProps{3}, 'frame')
                    text(h.Children.XLim(1)+height/20, h.Children.YLim(2)-width/20, sprintf('Frame: %d', i), 'Color', text_color, 'FontSize', fontSize, 'Parent', h.Children, 'VerticalAlignment', 'top')
                else
                    if isnumeric(data.frames(i).Time)
                        text(h.Children.XLim(1)+height/20, h.Children.YLim(2)-width/20, sprintf('Time: %g %s', (data.frames(i).Time-data.frames(1).Time)*timeScaling, labelProps{3}), 'Color', text_color, 'FontSize', fontSize, 'Parent', h.Children, 'VerticalAlignment', 'top')
                    else
                        text(h.Children.XLim(1)+height/20, h.Children.YLim(2)-width/20, sprintf('Time: %s %s', data.frames(i).Time, labelProps{3}), 'Color', text_color, 'FontSize', fontSize, 'Parent', h.Children, 'VerticalAlignment', 'top')
                    end
                end
            end
            
            h.Children.Units = 'normalized';
            h.Children.Position = [0 0 1 1];
            
            % Apply the initial color limits to each frame
            if i == 1
                CLim = data.axes.main.CLim;
            else
                h.Children.CLim = CLim;
            end
            
            set(h, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 width/height*20 20], 'InvertHardCopy', 'off');
            
            switch ext
                case '.png'
                    print(h, '-dpng','-r300',fullfile(directory, filenameSeries));
                case '.jpg'
                    print(h, '-djpeg','-r300',fullfile(directory, filenameSeries));
                case '.eps'
                    print(h, '-depsc ','-r300', '-painters' ,fullfile(directory, filenameSeries));
                otherwise
                    F(i) = getframe(h);
            end
            
            hbar.iterate(1);
            
        catch
            fprintf('Image %d cound not be saved -> aborted\n', i)
            break;
        end
    end
    
    if numel(range) > 1
        try
            delete(h);
            
            if makeMovie
                
                v = VideoWriter(fullfile(directory, filenameFull), videoTypes{extIdx, 2});
                try
                    v.FrameRate = str2num(movieProps{1});
                end
                try
                    v.Quality = str2num(movieProps{2});
                end
                
                open(v)
                writeVideo(v,F)
                close(v)
            end
        catch 
            msgbox('Could not write movie!', 'Error', 'error', 'modal')
        end
        
        
    else
        h.Visible = 'On';
        h.Name = 'Screenshot (can be closed)';
    end
    

    close(hbar);
    updateWaitbar(data.axes.progress, 0)
    cancelButton.Enable = 'off';
    displayStatus(src, [], '')
    %delete(h);
    toggleBusyPointer(data, 0)
    
end

