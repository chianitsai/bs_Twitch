%This scrips is to plot the alignement factors saved in alignement_data.mat
%OUTPUT= is a graph of the alignment factor. 
         %Every black circle is a day ,the red line is the mean
clear all
close all

%% Pre-run Settings
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'G:\Marco\bs_Twitch_results\alignment_motile\';

%% Modify
only_plot = 0; % if 0 reads, analyses and saves before plotting
save_graphs = 1; % 1 saves the graphs, 0 does not save the graphs

aspect = 1/3; % width of the graph

limit_ratio=0.69; % ratio of intensity of the two poles; for all cells set limit to 1
alignment_limit=0; % alignment factor threshold (counts cells with alignment factor above this value)

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_alignment_motile(limit_ratio,alignment_limit,save_dir);
else
    data_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\alignment_motile\mat_files\';
    data_name = 'file name'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
    data_dir_name = strcat(data_dir,data_name,'.mat');
end

save_name = regexprep(data_name, '_alignment_motile','_');
load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

%% Strains % Could still be done in a more elegant way!
strain_1 = 1;
strain_2 = 1;
strain_3 = 1;
strain_4 = 1;
strain_5 = 0;

do_strain=[strain_1,strain_2,strain_3,strain_4,strain_5]; 

%% Graph
index=find(do_strain==1);
nbr_collumn=sum(do_strain);
% colour = ["b o","m o","g o","r o"];
colour = ["k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o"];

figure('units','normalized','outerposition',[0 0 aspect 1])

for i=1:1:nbr_collumn
     type=index(1,i);
     data=align_counts{type,2};
     num_day=unique(data(:,1));
     mean_day=zeros(size(num_day,1),1);
     for day=1:1:size(num_day,1)
        indice=find(data(:,1)==num_day(day));
        mean_day(day,1)=(sum(data(indice,3))/sum(data(indice,4)))*100;
        tracks_total_day = sum(align_counts{type, 2}(indice,4));
        
        hold on
        plot(type,mean_day(day,1),colour(day),'MarkerSize',8, 'Linewidth',1.5);
        text(type+0.2,mean_day(day,1),num2str(tracks_total_day));
     end
     total_mean=mean(mean_day(:,1));
     hold on 
     plot([type-0.1 type+0.1], [total_mean total_mean], 'k-','Linewidth',1.5);    
end
set(gca, 'XTickLabel',{'',align_counts{:,1}},'Fontsize',15,'TickLabelInterpreter','none')
ylabel('Fraction of cells with Alignment > 0 (%)')
title('Moving Asymmetric Cells');
axis([0 nbr_collumn+1 0 100])
xticks([0:1:nbr_collumn+1])
xtickangle(15)

graph_type = 'alignment_motile';
if save_graphs
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
end

%% Histogram of all Alignment factors

index=find(do_strain==1);
nbr_collumn=sum(do_strain);
leg = [];

% figure('units','normalized','outerposition',[0 0 1 1])
% hold on

for i=1:1:nbr_collumn
    figure('units','normalized','outerposition',[0 0 1 1])
    type=index(1,i);
    data=align_counts{type,3};

    histogram(data,20,'Normalization','probability');
    axis([-1.2 1.2 0 1])
    title('Histogram of Alignment Factors of Asymmetric Moving Cells','FontSize',15);
    xlabel('Alignment factor','FontSize',15)
    ylabel('Probability','FontSize',15)
    legend(align_counts{type, 1},'FontSize',15,'Interpreter','none','Location','northwest')
%     leg = [leg, align_counts{type, 1}];

end
% legend(leg,'FontSize',15,'Interpreter','none','Location','northwest')
