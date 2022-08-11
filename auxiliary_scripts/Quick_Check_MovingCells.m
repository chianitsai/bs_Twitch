close all
clear all
%% Set directories
dir_data='G:\Marco\bs_Twitch_data_storage\';
dir_func='C:\Users\mkuehn\git\bs_Twitch\basic_analysis\Matlab_scripts\';
addpath(strcat(dir_func,'Functions'));
addpath(dir_func);
%% Set data

moving_only = 1;

[num,txt,~]=xlsread('Data_Input_Basic_Analysis.xlsx'); % must be located in 'directory'
dates = num(:,1); % read as a column vector
Pil_types = txt(:,1); % read as a cell with one column
intervals = txt(:,3); % read as a cell with one column
clear num txt
%% Load Variables Loop over all samples
m = 0;
for sample = 1:size(intervals,1)
    m = m+1;
    Pil_type = Pil_types{sample};
    date = dates(sample);
    interval = intervals{sample};

    adresse_data = strcat(dir_data,Pil_type,'\',num2str(date),'\',interval);
    nbr_folders = length(dir(adresse_data))-2;

    %% Loop over all folders
    for folder = 1:nbr_folders
        adresse_data=strcat(dir_data,Pil_type,'\',num2str(date),'\',interval,'\',num2str(folder));
        addpath(adresse_data)
        
        if moving_only
            load(strcat(adresse_data,'\variables.mat'),'cell_prop')
            result{folder,1} = 'Folder';
            result{folder,2} = folder;
            result{folder,3} = size(cell_prop,1);
        else
            load('variables.mat','cell_prop','cell_prop_non_moving')
            cell_info =  vertcat(cell_prop,cell_prop_non_moving);
            result{folder,1} = 'Folder';
            result{folder,2} = folder;
            result{folder,3} = size(cell_info,1);
        end
    end
    results_combined{m,1} = Pil_type;
    results_combined{m,2} = date;
    results_combined{m,3} = interval;
    if moving_only
        results_combined{m,4} = "only moving fraction";
    else
        results_combined{m,4} = "moving + non-moving fraction";
    end
    results_combined{m,5} = sum([result{:,3}]);
end