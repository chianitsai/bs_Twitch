function [save_dir_name, save_name] = save_polar_loc_speed_motile(mean_median)

func_mean_median = str2func(mean_median); % makes a function out of the string mean_median to calculate mean or median

%% Saves the file polar_localization_speed_motile.mat
% saves a file containing the values required for plotting the speed of
% cells, the polar localization motile index and PLMI vs speed
% saves a cell called polar_loc_speed_motile_results with the following columns:
    % column 1: Pil type
    % column 2: date
    % column 3: cell with speed information
        % column 1: track ID
        % column 2: number of frames tracked 
        % column 3: mean or median over all tracked frames of the filtred speed in µm/s (note if speed_limit = 0 filtered = unfiltered speed)
    % column 4: median speed over all tracks of the replicate
    
% saves a cell called polar_loc_speed_motile_all_speeds with the following columns:
    % column 1: Pil type of the data (for documentation purpose)
	% column 0: all dates of the data (for documentation purpose)
	% column 3: speed in µm/s for all replicates combined (mean or median of all tracks of all frames
	% column 4: number of tracks

%% To modify:

dir_data_input='C:\Users\mkuehn\git\bs_Twitch\graph_plotting\';
dir_data='G:\Marco\bs_Twitch_data_storage\';
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\polar_loc_speed_motile\mat_files\';

% Select folders from csv file (Format column 1, 2, 3 must be Pil_types, dates, intervals, respectively)
[num,txt,~]=xlsread(strcat(dir_data_input,'Data_Input_Graph_Plotting.xlsx')); % must be located in 'dir_data_input'
dates = num(:,1); % read as a column vector
dates_unique = unique(dates);
Pil_types = txt(:,1); % read as a cell with one column
intervals = txt(:,3); % read as a cell with one column

%% Loop over all Pil_types + dates + intervals
m = 0;
Pil_nums = [];
polar_loc_speed_motile_results = cell(size(Pil_types,1),4);
for strain=1:1:size(Pil_types,1)
    m = m+1;

    Pil_type=convertCharsToStrings(Pil_types{strain});
    Pil_nums = [Pil_nums, sscanf(Pil_type,'%i')];
    date=convertCharsToStrings(num2str(dates(strain)));
    interval=convertCharsToStrings(intervals{strain});
    
    adresse_data=strcat(dir_data,Pil_type,'\',date,'\',interval,'\');
    num_folder=length(dir(adresse_data))-2;

  %% Loop over all folders

  data_comb_folders = [];
  for folder=1:1:num_folder
    %% Load variables and add path
    addpath(strcat(dir_func,'Functions'));
    adresse=strcat(adresse_data,num2str(folder));
    addpath(adresse)
    load(strcat(adresse,'\variables_noSL.mat'),'cell_prop','BactID','Data_speed')
    load(strcat(adresse,'\parameters.mat'),'delta_x');
    
    nbr_bact=size(BactID,1);

    %% loop over all cells (rather all tracks)
    
    data = cell(nbr_bact,3);
    for nbr=1:1:nbr_bact    
        %% Get basic track information
        data{nbr,1} = cell_prop{nbr,1}; % track ID
        data{nbr,2} = cell_prop{nbr,2}; % number of frames tracked 
        
        %% Get speed
        data{nbr,3} = func_mean_median(Data_speed{nbr, 4}(:,1)); % speed of cell for every frame; filtered speed (if speed_limit = 0 this is like the unfiltered speed)
                
        %% Get polar vs cytoplasmic ratio
        

            
    end
    data_comb_folders = [data_comb_folders;data]; % combines the data of all folders
    
  end
  
    polar_loc_speed_motile_results{m,1} = Pil_type;
    polar_loc_speed_motile_results{m,2} = date;
    polar_loc_speed_motile_results{m,3} = data_comb_folders; % track ID, tracked frames and 
    polar_loc_speed_motile_results{m,4} = median([polar_loc_speed_motile_results{m,3}{:,3}]);

  rmpath(adresse)
end

%% Process: Delete empty replicates and get single_track speeds

Pil_types=unique(Pil_types);
nbr_strains = size(Pil_types,1);
polar_loc_speed_motile_all_speeds = cell(nbr_strains,4);

for strain = 1:1:nbr_strains
    Pil_type=Pil_types{strain};
    % find replicates with emtpy speed cells and delete them
    index_type=find([polar_loc_speed_motile_results{:,1}]==Pil_type);
    nbr_replicates = size(index_type,2);
    is_emtpy = zeros(nbr_replicates,1);
    for rep = 1:1:nbr_replicates
        if isempty(polar_loc_speed_motile_results{index_type(rep),3})
            is_emtpy(rep) = 1;
        else
            is_emtpy(rep) = 0;
        end
    end
    index_empty = find(is_emtpy);
    if ~isempty(index_empty)
        polar_loc_speed_motile_results(index_type(index_empty),:)=[];
    end
    
    % save single-track speeds in all_speeds cell
    speeds_concat = [];
    date_concat = [];
    for rep = 1:1:nbr_replicates
        if iscell(polar_loc_speed_motile_results{index_type(rep),3})

        % for each replicate get the speed of individual tracks
        speeds_rep = [polar_loc_speed_motile_results{index_type(rep),3}{:,3}];
        
        % concatenate the median speeds for al tracks for all replicates
        % also all dates
        speeds_concat = [speeds_concat,speeds_rep];
        date_concat = [date_concat;polar_loc_speed_motile_results{rep, 2}];
        end
    end
polar_loc_speed_motile_all_speeds{strain,1} = Pil_type; % Pil type of the data (for documentation purpose)
polar_loc_speed_motile_all_speeds{strain,2} = date_concat; % all dates of the data (for documentation purpose)
polar_loc_speed_motile_all_speeds{strain,3} = speeds_concat; % speed in µm/s for all replicates combined (mean or median of all tracks of all frames
polar_loc_speed_motile_all_speeds{strain,4} = size(speeds_concat,2); % number of tracks
end


Pil_nums_unique = unique(Pil_nums);
save_name = strcat(regexprep(num2str(dates_unique'),'  ','_'),'_Strains_', regexprep(num2str(Pil_nums_unique),'  ','_'), '_polar_loc_speed_motile');
save_dir_name = strcat(save_dir,save_name);

save(save_dir_name,'polar_loc_speed_motile_results','polar_loc_speed_motile_all_speeds');
end
