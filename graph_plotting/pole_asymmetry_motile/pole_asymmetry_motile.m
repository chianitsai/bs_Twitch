%the function to the graphs for asymmetric and symmetric distribution
%OUTPUT= 3 different graph with the distribution of symm and asymm cells 
         %Every black circle is a day ,the red line is the mean
         % 1 graph for moving cells
         % 1 graph for non moving cells
         % 1 graph for all the cells
         
         
clear all
close all

%% Pre-run Settings
dir_func='/Volumes/Gani_sv_WS/git/bs_Twitch/';
save_dir = '/Volumes/Gani_sv_WS/bs_Twitch_results/pole_asymmetry_motile/';

only_plot = 0; % if 0 reads, analyses and saves before plotting
save_graphs = 1; % 1 saves the graphs, 0 does not save the graphs

limite_ratio=0.69;
useMax = 1; % Important: Added the option to use ratio of max pole intenstiy instead of mean. Function get_symm_asymm now requries useMax!

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_pole_asymmetry_motile(limite_ratio,useMax,save_dir);
else
    data_dir = '/Volumes/Gani_sv_WS/bs_Twitch_results/pole_asymmetry_motile/mat_files/';
    data_name = '20230331_Strains_1756_pole_asymmetry_motile'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
    data_dir_name = strcat(data_dir,data_name,'.mat');
end

save_name = regexprep(data_name, '_pole_asymmetry_motile','_');
load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

%% Strains % Could still be done in a more elegant way!
strain_1 = 1;
strain_2 = 1;
strain_3 = 1;
strain_4 = 1;
strain_5 = 0;

do_strain=[strain_1,strain_2,strain_3,strain_4,strain_5]; 

%% Graph
%Moving cells
index=find(do_strain==1);
nbr_collumn=sum(do_strain);
% colour = ["b o","m o","g o","r o","c o","k o","y o"];
colour = ["k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o"];

figure('units','normalized','outerposition',[0 0 1 1])

subplot(1,3,1)
for i=1:1:nbr_collumn      
      type=index(1,i);
      data=moving_distribution{type,2};
      num_day=unique(data(:,1));
      mean_day=zeros(size(num_day,1),1);
      for day=1:1:size(num_day,1)
        indice=find(data(:,1)==num_day(day));
        mean_day(day,1)=(sum(data(indice,3))/sum(data(indice,4)))*100;
        tracks_total_day = sum(moving_distribution{type, 2}(indice,4));
        
        hold on
        plot(type,mean_day(day,1),colour(day),'MarkerSize',8, 'Linewidth',1.5);
        text(type+0.2,mean_day(day,1),num2str(tracks_total_day));
      end  
      total_mean=mean(mean_day(:,1));
      hold on 
      plot([type-0.1 type+0.1], [total_mean total_mean], 'k-','Linewidth',1.5);            
end   
set(gca, 'XTickLabel',{'',moving_distribution{:,1}}, 'Fontsize',15, 'TickLabelInterpreter','none')
ylabel('Fraction of asymmetric cell [%]')
title('Moving cells');
axis([0 nbr_collumn+1 0 100])
xticks([0:1:nbr_collumn])
xtickangle(15)

%% non-moving cells
subplot(1,3,2)
for i=1:1:nbr_collumn
      type=index(1,i);
      data=non_moving_distribution{type,2};
      num_day=unique(data(:,1));
       mean_day=zeros(size(num_day,1),1);
      for day=1:1:size(num_day,1)
        indice=find(data(:,1)==num_day(day));
        mean_day(day,1)=(sum(data(indice,3))/sum(data(indice,4)))*100;
        tracks_total_day = sum(non_moving_distribution{type, 2}(indice,4));
        
        hold on
        plot(type,mean_day(day,1),colour(day),'MarkerSize', 8, 'Linewidth',1.5);
        text(type+0.2,mean_day(day,1),num2str(tracks_total_day));
      end  
      total_mean=mean(mean_day(:,1));
      hold on 
      plot([type-0.1 type+0.1], [total_mean total_mean], 'k-','Linewidth',2);            
end   
set(gca, 'XTickLabel',{'',moving_distribution{:,1}}, 'Fontsize',15, 'TickLabelInterpreter','none')
ylabel('Fraction of asymmetric cell [%]')
title('Non Moving cells');
axis([0 nbr_collumn+1 0 100])
xticks([0:1:nbr_collumn])
xtickangle(15)

%% all cells
%figure('units','normalized','outerposition',[0 0 1 1])
subplot(1,3,3)
for i=1:1:nbr_collumn
    type=index(1,i);
      data1=moving_distribution{type,2};
      data2=non_moving_distribution{type,2};
      num_day=unique(data1(:,1));
      mean_day=zeros(size(num_day,1),1);
      for day=1:1:size(num_day,1)
        indice1=find(data1(:,1)==num_day(day));
        mean_day(day,1)=(sum(data1(indice1,3)+data2(indice1,3))/sum(data1(indice1,4)+data2(indice1,4)))*100;
        tracks_total_day = sum(moving_distribution{type, 2}(indice1,4)) + sum(non_moving_distribution{type, 2}(indice1,4));
        
        hold on
        plot(type,mean_day(day,1),colour(day),'MarkerSize', 8, 'Linewidth',1.5);
        text(type+0.2,mean_day(day,1),num2str(tracks_total_day));
      end  
      total_mean=mean(mean_day(:,1));
      hold on 
      plot([type-0.1 type+0.1], [total_mean total_mean], 'k-','Linewidth',2);
end   
%grid on
set(gca, 'XTickLabel',{moving_distribution{:,1}}, 'Fontsize',15, 'TickLabelInterpreter','none')
ylabel('Fraction of asymmetric cell [%]')
title('All cells');
axis([0 nbr_collumn+1 0 100])
xticks([1:1:nbr_collumn])
xtickangle(15)

graph_type = 'asymmetry_motile';
if save_graphs
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files/',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files/',save_name,graph_type,'.svg'));
end