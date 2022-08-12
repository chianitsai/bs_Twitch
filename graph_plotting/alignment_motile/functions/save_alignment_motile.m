function [save_dir_name, save_name] = save_displacement_maps(limit_ratio,alignment_limit)
% run before for graph alignement 

dir_data_input='C:\Users\mkuehn\git\bs_Twitch\graph_plotting\';
dir_data='G:\Marco\bs_Twitch_data_storage\';
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\alignment_motile\mat_files\';

%% load functions
addpath(strcat(dir_func,'Functions')); 
% addpath(directory);

%% laod input
[num,txt,~]=xlsread(strcat(dir_data_input,'Data_Input_Graph_Plotting.xlsx')); % must be located in 'dir_data_input'
dates_all = num2cell(num(:,1)); % read as a column vector
dates_unique = unique(num(:,1));
Pil_types = txt(:,1); % read as a cell with one column
Pil_types_unique = unique(txt(:,1));
intervals_all = txt(:,3); % read as a cell with one column

%% Loop over all Pil_types + dates + intervals
m = 0;
Pil_nums = [];
for type=1:1:size(Pil_types_unique,1)
    m = m+1;
    index = find(contains(Pil_types, Pil_types_unique{type}));
    Pil_type = Pil_types_unique{type}
    Pil_nums = [Pil_nums, sscanf(Pil_type,'%i')];
    dates = dates_all(index);
    intervals = intervals_all(index);
    
    [align_counts{m,2},align_counts{m,3}]=get_alignment_motile(dir_data,Pil_type,dates,intervals,limit_ratio,alignment_limit); 
    align_counts{m,1}=Pil_type;

    clear dates intervals
end  

%% save data 
Pil_nums_unique = unique(Pil_nums);
save_name = strcat(regexprep(num2str(dates_unique'),'  ','_'),'_Strains_', regexprep(num2str(Pil_nums_unique),'  ','_'), '_alignment_motile');
save_dir_name = strcat(save_dir,save_name);

save(save_dir_name,'align_counts','limit_ratio');
end