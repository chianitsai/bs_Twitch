function [save_dir_name, save_name] = save_polar_loc_speed_motile(mean_median,two_ch,addition)

func_mean_median = str2func(mean_median); % makes a function out of the string mean_median to calculate mean or median

%% Saves the file polar_localization_speed_motile.mat
% saves a file containing the values required for plotting the speed of
% cells, the polar localization motile index and PLMI vs speed
% saves a cell called polar_loc_speed_motile_results with the following columns:
    % column 1: Pil type
    % column 2: date
    % column 3: cell with speed information
        % column 1: Folder number
        % column 2: track ID
        % column 3: number of frames tracked 
        % column 4: filtered speed per track for each tracked frames in µm/s (note if speed_limit = 0 filtered = unfiltered speed)
        % column 5: mean or median over all tracked frames of column 4
        % column 6: ratio pole vs cytoplasm per track for each tracked frame, mean of the mean intensities of both poles
        % column 7: mean or median over all tracked frames of column 6
        % column 8: ratio pole vs cytoplasm per track for each tracked frame, max of the mean intensities of both poles, i.e. mean intensity of the bright pole
        % column 9: mean or median over all tracked frames of column 8
        % column 10: ratio pole vs cytoplasm per track for each tracked frame, total intensities, note: total pole and cyto may vary a lot due to different size
        % column 11: mean or median over all tracked frames of column 11
    % column 4: median speed over all tracks of the replicate
    
% saves a cell called polar_loc_speed_motile_concat with the following columns:
    % column 1: Pil type of the data (for documentation purpose)
	% column 0: all dates of the data (for documentation purpose)
	% column 3: all speeds 
    % column 4: all polar ratios (mean pole) 
    % column 5: all polar ratios (max pole) 
    % column 6: all polar ratios (total intensities)
	% column 7: number of tracks

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
nbr_Pil_types = size(Pil_types,1);

%% Loop over all Pil_types + dates + intervals
m = 0;
Pil_nums = [];
polar_loc_speed_motile_results = cell(nbr_Pil_types,7);
for strain=1:1:nbr_Pil_types
    m = m+1;

    Pil_type=convertCharsToStrings(Pil_types{strain});
    Pil_nums = [Pil_nums, sscanf(Pil_type,'%i')];
    date=convertCharsToStrings(num2str(dates(strain)));
    interval=convertCharsToStrings(intervals{strain});
    
    disp(strcat("Working on strain ",Pil_type," date ",date," ",interval))
    
    adresse_data=strcat(dir_data,Pil_type,'\',date,'\',interval,'\');
    num_folder=length(dir(adresse_data))-2;

  %% Step 1: get and save speed + polar vs cytoplasmic ratio

  data_comb_folders = [];
  for folder=1:1:num_folder
    %% Load variables and add path
    addpath(strcat(dir_func,'Functions'));
    adresse=strcat(adresse_data,num2str(folder));
    addpath(adresse)
    load(strcat(adresse,'\variables',addition,'.mat'),'cell_prop','BactID','Data_speed')
    load(strcat(adresse,'\parameters.mat'),'delta_x');
    
    nbr_bact=size(BactID,1);

    %% loop over all cells (rather all tracks)
    
    data = cell(nbr_bact,8);
    for nbr=1:1:nbr_bact    
        %% Get basic track information
        data{nbr,1} = strcat("Folder ",num2str(folder)); % folder number
        data{nbr,2} = cell_prop{nbr,1}; % track ID
        data{nbr,3} = cell_prop{nbr,2}; % number of frames tracked 
        
        %% Get speed averaged over time and from frame 2 to last
        data{nbr,4} = Data_speed{nbr, 4}(2:end,1);
        data{nbr,5} = func_mean_median(Data_speed{nbr, 4}(2:end,1)); % speed of cell for every frame; filtered speed (if speed_limit = 0 this is like the unfiltered speed)
        
        %% Get polar vs cytoplasmic ratio
        
        data{nbr,6} = [cell_prop{nbr,6}{:,2}]' ./ cell_prop{nbr,12}; % ratio mean of mean pole intensity divided by mean cytoplamisc intensity
        data{nbr,7} = func_mean_median(data{nbr,6});
        data{nbr,8} = [cell_prop{nbr,6}{:,3}]' ./ cell_prop{nbr,12}; % ratio max of mean pole intensity divided by mean cytoplamisc intensity
        data{nbr,9} = func_mean_median(data{nbr,8});
        data{nbr,10} = cell_prop{nbr,11} ./ cell_prop{nbr,13}; % ratio mean of mean pole intensity divided by mean cytoplamisc intensity
        data{nbr,11} = func_mean_median( data{nbr,10});
%         pole_mean = cell_prop{nbr, 6}{1, 1};  % mean polar intensity; mean/median over time; MAX of the two poles, i.e. takes the value of the brighter pole
%         cyto_mean = [];% mean cytoplasmic intensity; mean/median over time
        
%         pole_total = [];% total polar intensity; mean/median over time
%         cyto_total = [];% total cytoplasmic intensity; mean/median over time
            
    end
    data_comb_folders = [data_comb_folders;data]; % combines the data of all folders
    
  end
  
    polar_loc_speed_motile_results{m,1} = Pil_type;
    polar_loc_speed_motile_results{m,2} = date;
    polar_loc_speed_motile_results{m,3} = data_comb_folders; % track ID, tracked frames and 
    polar_loc_speed_motile_results{m,4} = median([polar_loc_speed_motile_results{m,3}{:,5}]); % median speed of this replicate
    polar_loc_speed_motile_results{m,5} = median([polar_loc_speed_motile_results{m,3}{:,7}]); % median mean-mean polar ratio of this replicate
    polar_loc_speed_motile_results{m,6} = median([polar_loc_speed_motile_results{m,3}{:,9}]); % median max-mean polar ratiospeed of this replicate
    polar_loc_speed_motile_results{m,7} = median([polar_loc_speed_motile_results{m,3}{:,11}]); % median total int polar ratio of this replicate

  rmpath(adresse)
end

%% Step 2: Save speed and polar loc results concatenated together for distribution plotting

Pil_types_unique=unique(Pil_types);
nbr_strains = size(Pil_types_unique,1);
polar_loc_speed_motile_concat = cell(nbr_strains,4);

for strain = 1:1:nbr_strains
    Pil_type=Pil_types_unique{strain};
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
    
    % save single-track speeds and polar ratios in concat cell
    speeds_concat = [];
    mean_mean_ratio_concat = [];
    max_mean_ratio_concat = [];
    total_ratio_concat = [];
    date_concat = [];
    for rep = 1:1:nbr_replicates
        if iscell(polar_loc_speed_motile_results{index_type(rep),3})

        % for each replicate get the data of individual tracks
        speeds_rep = [polar_loc_speed_motile_results{index_type(rep),3}{:,5}];
        mean_mean_ratio_rep = [polar_loc_speed_motile_results{index_type(rep),3}{:,7}];
        max_mean_ratio_rep = [polar_loc_speed_motile_results{index_type(rep),3}{:,9}];
        total_ratio_rep = [polar_loc_speed_motile_results{index_type(rep),3}{:,11}];
        
        % concatenate the median data for al tracks for all replicates
        % also all dates
        speeds_concat = [speeds_concat,speeds_rep];
        mean_mean_ratio_concat = [mean_mean_ratio_concat,mean_mean_ratio_rep];
        max_mean_ratio_concat = [max_mean_ratio_concat,max_mean_ratio_rep];
        total_ratio_concat = [total_ratio_concat,total_ratio_rep];
        date_concat = [date_concat;polar_loc_speed_motile_results{rep, 2}];
        end
    end
polar_loc_speed_motile_concat{strain,1} = Pil_type; % Pil type of the data (for documentation purpose)
polar_loc_speed_motile_concat{strain,2} = date_concat; % all dates of the data (for documentation purpose)
polar_loc_speed_motile_concat{strain,3} = speeds_concat; % speed in µm/s for all replicates combined (mean or median of all tracks of all frames
polar_loc_speed_motile_concat{strain,4} = mean_mean_ratio_concat; % single track mean-mean polar ratios of this replicate
polar_loc_speed_motile_concat{strain,5} = max_mean_ratio_concat; % single track max-mean polar ratios of this replicate
polar_loc_speed_motile_concat{strain,6} = total_ratio_concat; % single track total int polar ratios of this replicate
polar_loc_speed_motile_concat{strain,7} = size(speeds_concat,2); % number of tracks
end

%% Repeat for channel 2 if it exists

if two_ch
    m = 0;
    Pil_nums = [];
    polar_loc_speed_motile_results_ch2 = cell(nbr_Pil_types,7);
    for strain=1:1:nbr_Pil_types
        m = m+1;

        Pil_type=convertCharsToStrings(Pil_types{strain});
        Pil_nums = [Pil_nums, sscanf(Pil_type,'%i')];
        date=convertCharsToStrings(num2str(dates(strain)));
        interval=convertCharsToStrings(intervals{strain});

        disp(strcat("Working on strain ",Pil_type," date ",date," ",interval," channel 2"))

        adresse_data=strcat(dir_data,Pil_type,'\',date,'\',interval,'\');
        num_folder=length(dir(adresse_data))-2;

      %% Step 1: get and save speed + polar vs cytoplasmic ratio

      data_comb_folders = [];
      for folder=1:1:num_folder
        %% Load variables and add path
        addpath(strcat(dir_func,'Functions'));
        adresse=strcat(adresse_data,num2str(folder));
        addpath(adresse)
        load(strcat(adresse,'\variables',addition,'.mat'),'cell_prop_ch2','BactID','Data_speed')
        load(strcat(adresse,'\parameters.mat'),'delta_x');

        nbr_bact=size(BactID,1);

        %% loop over all cells (rather all tracks)

        data = cell(nbr_bact,8);
        for nbr=1:1:nbr_bact    
            %% Get basic track information
            data{nbr,1} = strcat("Folder ",num2str(folder)); % folder number
            data{nbr,2} = cell_prop_ch2{nbr,1}; % track ID
            data{nbr,3} = cell_prop_ch2{nbr,2}; % number of frames tracked 

            %% Get speed averaged over time and from frame 2 to last
            data{nbr,4} = Data_speed{nbr, 4}(2:end,1);
            data{nbr,5} = func_mean_median(Data_speed{nbr, 4}(2:end,1)); % speed of cell for every frame; filtered speed (if speed_limit = 0 this is like the unfiltered speed)

            %% Get polar vs cytoplasmic ratio

            data{nbr,6} = [cell_prop_ch2{nbr,6}{:,2}]' ./ cell_prop_ch2{nbr,12}; % ratio mean of mean pole intensity divided by mean cytoplamisc intensity
            data{nbr,7} = func_mean_median(data{nbr,6});
            data{nbr,8} = [cell_prop_ch2{nbr,6}{:,3}]' ./ cell_prop_ch2{nbr,12}; % ratio max of mean pole intensity divided by mean cytoplamisc intensity
            data{nbr,9} = func_mean_median(data{nbr,8});
            data{nbr,10} = cell_prop_ch2{nbr,11} ./ cell_prop_ch2{nbr,13}; % ratio mean of mean pole intensity divided by mean cytoplamisc intensity
            data{nbr,11} = func_mean_median( data{nbr,10});
    %         pole_mean = cell_prop_ch2{nbr, 6}{1, 1};  % mean polar intensity; mean/median over time; MAX of the two poles, i.e. takes the value of the brighter pole
    %         cyto_mean = [];% mean cytoplasmic intensity; mean/median over time

    %         pole_total = [];% total polar intensity; mean/median over time
    %         cyto_total = [];% total cytoplasmic intensity; mean/median over time

        end
        data_comb_folders = [data_comb_folders;data]; % combines the data of all folders

      end

        polar_loc_speed_motile_results_ch2{m,1} = Pil_type;
        polar_loc_speed_motile_results_ch2{m,2} = date;
        polar_loc_speed_motile_results_ch2{m,3} = data_comb_folders; % track ID, tracked frames and 
        polar_loc_speed_motile_results_ch2{m,4} = median([polar_loc_speed_motile_results_ch2{m,3}{:,5}]); % median speed of this replicate
        polar_loc_speed_motile_results_ch2{m,5} = median([polar_loc_speed_motile_results_ch2{m,3}{:,7}]); % median mean-mean polar ratio of this replicate
        polar_loc_speed_motile_results_ch2{m,6} = median([polar_loc_speed_motile_results_ch2{m,3}{:,9}]); % median max-mean polar ratiospeed of this replicate
        polar_loc_speed_motile_results_ch2{m,7} = median([polar_loc_speed_motile_results_ch2{m,3}{:,11}]); % median total int polar ratio of this replicate

      rmpath(adresse)
    end

    %% Step 2: Save speed and polar loc results concatenated together for distribution plotting

    polar_loc_speed_motile_concat_ch2 = cell(nbr_strains,4);

    for strain = 1:1:nbr_strains
        Pil_type=Pil_types_unique{strain};
        % find replicates with emtpy speed cells and delete them
        index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==Pil_type);
        nbr_replicates = size(index_type,2);
        is_emtpy = zeros(nbr_replicates,1);
        for rep = 1:1:nbr_replicates
            if isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
                is_emtpy(rep) = 1;
            else
                is_emtpy(rep) = 0;
            end
        end
        index_empty = find(is_emtpy);
        if ~isempty(index_empty)
            polar_loc_speed_motile_results_ch2(index_type(index_empty),:)=[];
        end

        % save single-track speeds and polar ratios in concat cell
        speeds_concat = [];
        mean_mean_ratio_concat = [];
        max_mean_ratio_concat = [];
        total_ratio_concat = [];
        date_concat = [];
        for rep = 1:1:nbr_replicates
            if iscell(polar_loc_speed_motile_results_ch2{index_type(rep),3})

            % for each replicate get the data of individual tracks
            speeds_rep = [polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,5}];
            mean_mean_ratio_rep = [polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,7}];
            max_mean_ratio_rep = [polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,9}];
            total_ratio_rep = [polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,11}];

            % concatenate the median data for al tracks for all replicates
            % also all dates
            speeds_concat = [speeds_concat,speeds_rep];
            mean_mean_ratio_concat = [mean_mean_ratio_concat,mean_mean_ratio_rep];
            max_mean_ratio_concat = [max_mean_ratio_concat,max_mean_ratio_rep];
            total_ratio_concat = [total_ratio_concat,total_ratio_rep];
            date_concat = [date_concat;polar_loc_speed_motile_results_ch2{rep, 2}];
            end
        end
    polar_loc_speed_motile_concat_ch2{strain,1} = Pil_type; % Pil type of the data (for documentation purpose)
    polar_loc_speed_motile_concat_ch2{strain,2} = date_concat; % all dates of the data (for documentation purpose)
    polar_loc_speed_motile_concat_ch2{strain,3} = speeds_concat; % speed in µm/s for all replicates combined (mean or median of all tracks of all frames
    polar_loc_speed_motile_concat_ch2{strain,4} = mean_mean_ratio_concat; % single track mean-mean polar ratios of this replicate
    polar_loc_speed_motile_concat_ch2{strain,5} = max_mean_ratio_concat; % single track max-mean polar ratios of this replicate
    polar_loc_speed_motile_concat_ch2{strain,6} = total_ratio_concat; % single track total int polar ratios of this replicate
    polar_loc_speed_motile_concat_ch2{strain,7} = size(speeds_concat,2); % number of tracks
    end
end

Pil_nums_unique = unique(Pil_nums);
save_name = strcat(regexprep(num2str(dates_unique'),'  ','_'),'_Strains_', regexprep(num2str(Pil_nums_unique),'  ','_'), '_polar_loc_speed_motile');
save_dir_name = strcat(save_dir,save_name);

if two_ch
    save(save_dir_name,'polar_loc_speed_motile_results','polar_loc_speed_motile_concat','polar_loc_speed_motile_results_ch2','polar_loc_speed_motile_concat_ch2');
else
    save(save_dir_name,'polar_loc_speed_motile_results','polar_loc_speed_motile_concat');
end
end
