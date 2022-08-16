%% Plots speed, polar localization motile average index and polar localization vs speed

clear all
close all

only_plot = 0; % if 0 reads, analyses and saves before plotting

mean_median = 'mean'; % defines if mean or median speed over all tracked timepoints

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_polar_loc_speed_motile(mean_median);
else
    data_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\polar_loc_speed_motile\mat_files\';
    data_name = '20220726_20220728_20220729_20220804_Strains_1634_1635_1638_polar_loc_speed_motile'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
    data_dir_name = strcat(data_dir,data_name,'.mat');
end

%% Pre-run Settings
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\polar_loc_speed_motile\';
save_name = regexprep(data_name, '_polar_loc_speed_motile','_');

load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

%% set options

tos = "2h";

plot_violin = 1; % plots distribution of single-track values as violin plot

plot_speed = 1; % plots speed
plot_polLoc = 1; % plots ratio polar intensity vs cytoplasm
type_ratio = "mean"; % "mean" or "max" or "total"

y_speed = 0.1;  % y-axis of speed plots
y_polLoc = 2;  % y-axis of pole vs cytoplasm ratio plots
scaling_violin_speed = 0.02; % scaling width of violin plots
scaling_violin_polLoc = 0.2; % scaling width of violin plots

aspect_data = 2; % 1/aspect_speed = width of the speed plot

%% Start looping

% Strains
Pil_types=unique([polar_loc_speed_motile_results{:,1}]);
nbr_strains = size(Pil_types,2);

% load functions
addpath(strcat(dir_func,'Functions')); 

% Diagram
colour = ["k","r","b","g","c","m","y"];

%% Plot speed all tracks

if plot_speed
    figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
    axis([0 nbr_strains+2 0 y_speed])
    hold on
    set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
    xticks([0:1:nbr_strains+1])
    xtickangle(15)
    ylabel("Twitching Speed (µm/s)")

    x_val = [];
    leg=[];
    for strain = 1:1:nbr_strains
        if nbr_strains<8
            colour_data = strcat(colour(strain)," o");
        else
            colour_data = strcat(colour(1)," o");
        end
        leg=[leg,Pil_types(strain)];  
               
        type=Pil_types(strain);
        index_type=find([polar_loc_speed_motile_results{:,1}]==type);
        nbr_replicates = size(index_type,2);

        x_val = [x_val,strain];
        for rep = 1:1:nbr_replicates
            if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
                plot(x_val(strain),polar_loc_speed_motile_results{index_type(rep),4},colour_data,'MarkerSize',8,'Linewidth',1) % plots median speed of the replicate
            end
        end
        mean_data = mean([polar_loc_speed_motile_results{index_type,4}]);       
        plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean speed over all replicates  
        text(x_val(strain), 0.005, num2str(polar_loc_speed_motile_concat{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
        if plot_violin
            violin(x_val(strain), polar_loc_speed_motile_concat{strain,3},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_speed) % plots distribution of single-track values combined for all replicates
        end
    end
    no_move = 0.01; % manually entered rough threshold for non-moving cells
    plot([0 nbr_strains+2],[no_move no_move],'k --','Linewidth',1)
    text(0.03,no_move+0.0015,"rough no-move threshold",'FontSize',8)
    title(strcat("Cell speed after ",tos," on surface"));
    
    graph_type = 'speed_unfiltered';
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
end

%% Plot polar to cytoplasmic ratio all tracks

if plot_polLoc
    [type_ratio_position] = type_ratio_position(type_ratio);
    
    figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
    axis([0 nbr_strains+2 0 y_polLoc])
    hold on
    set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
    xticks([0:1:nbr_strains+1])
    xtickangle(15)
    ylabel(strcat("Ratio pole vs cytoplams intensities (",type_ratio,")"))

    x_val = [];
    leg=[];
    for strain = 1:1:nbr_strains
        if nbr_strains<8
            colour_data = strcat(colour(strain)," o");
        else
            colour_data = strcat(colour(1)," o");
        end
        leg=[leg,Pil_types(strain)];  
               
        type=Pil_types(strain);
        index_type=find([polar_loc_speed_motile_results{:,1}]==type);
        nbr_replicates = size(index_type,2);

        x_val = [x_val,strain];
        for rep = 1:1:nbr_replicates
            if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
                plot(x_val(strain),polar_loc_speed_motile_results{index_type(rep),type_ratio_position(1)},colour_data,'MarkerSize',8,'Linewidth',1) % plots median polar loc ratio of the replicate
            end
        end
        mean_data = mean([polar_loc_speed_motile_results{index_type,type_ratio_position(1)}]);           
        plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates  
        text(x_val(strain), 0.05, num2str(polar_loc_speed_motile_concat{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
        if plot_violin
            violin(x_val(strain), polar_loc_speed_motile_concat{strain,type_ratio_position(2)},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
        end
    end
    no_polLoc = 0.65; % manually entered rough threshold for non-moving cells
    plot([0 nbr_strains+2],[no_polLoc no_polLoc],'k --','Linewidth',1)
    text(0.03,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8) % this threshold should be checked again
    title(strcat("Polar localization ratio after ",tos," on surface"));
    
    graph_type = strcat('polLoc_ratio_',type_ratio);
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
end

%% Plot polar loc ratio vs speed
% save it first
% figure it out first first
