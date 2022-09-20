function [save_dir_name, save_name] = save_pole2pole_oscillations(combined,move,filtered,save_dir)

dir_data_input='C:\Users\mkuehn\git\bs_Twitch\graph_plotting\';
dir_data='G:\Marco\bs_Twitch_data_storage\';
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = strcat(save_dir,'mat_files\');

%% load functions
addpath(strcat(dir_func,'Functions')); 

%% laod input

% Select folders from csv file (Format column 1, 2, 3 must be Pil_types, dates, intervals, respectively (see Table "Sample Information"))
[num,txt,~]=xlsread(strcat(dir_data_input,'Data_Input_Graph_Plotting.xlsx')); % must be located in 'dir_data'
dates = num(:,1); % read as a column vector
dates_unique = unique(dates);
Pil_types = txt(:,1); % read as a cell with one column
Pil_types_unique = unique(txt(:,1));
nbr_PTU = size(Pil_types_unique,1);
intervals = txt(:,3); % read as a cell with one column
clear num txt

%% Calculate stuff

pole2pole_data = cell(size(intervals,1),10);
for row = 1:size(pole2pole_data,1)
    pole2pole_data{row,4} = 0;
    pole2pole_data{row,5} = 0;
end

Pil_nums = [];
for sample = 1:size(intervals,1)
    Pil_type = Pil_types{sample};
    Pil_nums = [Pil_nums, sscanf(Pil_type,'%i')];
    date = dates(sample);
    interval = intervals{sample};

    adresse_folder = strcat(dir_data,Pil_type,'\',num2str(date),'\',interval);
    nbr_folders = length(dir(adresse_folder))-2;

    %% Loop over all folders
    for folder = 1:nbr_folders
        adresse_data=strcat(dir_data,Pil_type,'\',num2str(date),'\',interval,'\',num2str(folder));
        addpath(adresse_data)
        
        if combined
            load('variables.mat','cell_prop','cell_prop_non_moving')
            cell_info =  vertcat(cell_prop,cell_prop_non_moving);
        else           
            if move
                load('variables.mat','cell_prop')    
                cell_info=cell_prop;
            else
                load('variables.mat','cell_prop_non_moving')
                cell_info=cell_prop_non_moving;
            end
        end

        load('parameters.mat','delta_t')

        %% Loop over all cell tracks
        
        if size(cell_info,1) == 0 % if no tracks for that folder
            pole2pole_folder(1,1) = 0; % % number of cell track - set to 0
            pole2pole_folder(1,2) = 0; % number of frames tracked - set to 0
            pole2pole_folder(1,3) = 0; % total number of pole2pole switches for each cell track - set to 0
            pole2pole_folder(1,4) = NaN; % number of pole2pole switches normalized by time in minutes (i.e. X siwtches per min) - set to nothing
        else
            pole2pole_folder = zeros(size(cell_info,1),4);
            for nbr = 1:size(cell_info,1)
                %% Label poles correctly
                poles_coord = cell_info{nbr,5};
                poles_int_mean = cell_info{nbr,6};
                poles_int_max = cell_info{nbr,10};
                CM = cell_info{nbr,3};
                [pole_A,pole_B] = label_the_poles(poles_coord,CM,poles_int_mean,poles_int_max);
                clear poles_coord poles_int_mean poles_int_max
                %% Find pole2pole intensity change
                nbr_frames = size(pole_A,1);
                pole2pole =zeros(nbr_frames+1,3);

                for frame = 1:nbr_frames
                    if pole_A(frame,4) > pole_B(frame,4)
                        pole2pole(frame,1) = 1;
                    elseif pole_A(frame,4) < pole_B(frame,4)
                        pole2pole(frame,1) = -1;
                    end
                end
                %% Count pole2pole switches
                for frame = 2:nbr_frames % checks if there is a change from -1 to 1 or vice versa from previous to current frame
                    pole_switch = pole2pole(frame-1,1) + pole2pole(frame,1);
                    if pole_switch == 0
                        pole2pole(frame,2) = 1;   
                    else
                        pole2pole(frame,2) = 0;
                    end
                end
                for frame = 2:nbr_frames % adds additional column with "filtered" pole2pole switches (if 2 switches in subsequent frames, i.e. just change of bright pole for 1 frame, doesn't count)
                    pole_switch_filterd = pole2pole(frame-1,2) + pole2pole(frame,2) + pole2pole(frame+1,2);
                    if pole_switch_filterd == 0 | pole_switch_filterd == 1
                        pole2pole(frame,3) = pole2pole(frame,2);   
                    elseif pole_switch > 1
                        pole2pole(frame,3) = 0;
                    end
                end
                clear pole_switch
                %% Collect number of pole switches for each cell track and combine to matrix for all cell tracks in the current folder
                pole2pole_folder(nbr,1) = cell_info{nbr,1}; % number of cell track
                pole2pole_folder(nbr,2) = cell_info{nbr,2}; % number of frames tracked
                if filtered
                    pole2pole_folder(nbr,3) = sum(pole2pole(:,3)); % total number of pole2pole switches (filtered) for each cell track
                else
                    pole2pole_folder(nbr,3) = sum(pole2pole(:,2)); % total number of pole2pole switches (unfiltered) for each cell track
                end
                pole2pole_folder(nbr,4) = pole2pole_folder(nbr,3) / ((pole2pole_folder(nbr,2)*delta_t)/60); % number of pole2pole switches normalized by time in minutes (i.e. X siwtches per min)
            end
            clear pole2pole
        end
        %% Collect data over all folders for the current sample
        
        pole2pole_data{sample,1} = Pil_type;
        pole2pole_data{sample,2} = date;
        pole2pole_data{sample,3} = interval;    
        pole2pole_data{sample,4} = pole2pole_data{sample,4} + sum(pole2pole_folder(:,2)); % number of frames tracked, sum over all cell tracks
        pole2pole_data{sample,5} = pole2pole_data{sample,5} + sum(pole2pole_folder(:,3)); % number of pole2pole switches, sum over all cell tracks
        if isnan(pole2pole_folder(:,4))
            pole2pole_data{sample,7} = pole2pole_data{sample,7}; % if there's no tracks, leaves entry as it is
        else
            pole2pole_data{sample,7} = vertcat(pole2pole_data{sample,7},pole2pole_folder(:,4)); % concatenates all the cell track individual pole2pole switches
        end
        clear pole2pole_folder
    end
    if pole2pole_data{sample,4} == 0
        pole2pole_data{sample,6} = 0;
    else
        pole2pole_data{sample,6} = pole2pole_data{sample,5} / ((pole2pole_data{sample,4}*delta_t)/60); % frequency of pole2pole switches for this day (replicate) normalized by time in minute (i.e. X siwtches per min)
    end
    if isempty(pole2pole_data{sample,7})
        pole2pole_data{sample,8} = [];
    else
        pole2pole_data{sample,8} = mean(pole2pole_data{sample,7}(:,1)); % mean of cell track individual pole2pole switches
        pole2pole_data{sample,9} = median(pole2pole_data{sample,7}(:,1)); % median of cell track individual pole2pole switches
    end
    
    pole2pole_data{sample,10} = size(find(pole2pole_data{sample,7}(:,1)==0),1) / size(pole2pole_data{sample,7}(:,1),1); % fraction of cell tracks with 0 pole2pole swichtes
end

%% save data 
Pil_nums_unique = unique(Pil_nums);
save_name = strcat(regexprep(num2str(dates_unique'),'  ','_'),'_Strains_', regexprep(num2str(Pil_nums_unique),'  ','_'), '_pole2pole_oscillations');
save_dir_name = strcat(save_dir,save_name);

save(save_dir_name,'pole2pole_data');
end