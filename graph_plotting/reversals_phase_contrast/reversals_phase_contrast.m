%% Plot  reversal frequency of single twitching cells (phase contrast only)
clear all
close all

%% Pre-run Settings
dir_func='/Volumes/Gani_WS/git/bs_Twitch/';
save_dir = '/Volumes/Gani_WS/bs_Twitch_results/reversals_phase_contrast/';

%% To modify:
title_graph = "Time on surface = 2h"; %    Min limit time=2   Reversal time=5';

% only ativate one of the following options!!!
reversals_only = 0; % plots only filtered reversals
jiggles_only = 0; % plots only filtered jiggles
reversals_jiggles = 1; % plots reversals and jiggles all combined
number_cells_revjiggling = 0; % plots the number of cells that are reversing or jiggling normalized by number of tracks
rmsd_only = 0; % plots the median of the medians of the root mean square displacement per replicate
rev_rmsd = 0; % normalization by rmsd, doesn't make so much sense
% !!!

y_revs = 12; % for reversal frequencies typically 55, for number of reversing cells typically below 1
aspect = 2.5; % divides the figure width (normally screen width) by given number
plot_CI95 = 0; 
    plot_bs = 0; % decide if plotting "normal" CI95 or bootstrap CI95
plot_stdev = 0; 
plot_num_tracks = 0;

more_than_SIX_replicates = 1; % if more than 6 replicates the colours are all black, if not set to 1 produces error

only_plot = 0; % if 0 reads, analyses and saves before plotting
save_graphs = 1; % 1 saves the graphs, 0 does not save the graphs

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_reversals_phase_contrast(save_dir);
else
    data_dir = '/Volumes/Gani_WS/bs_Twitch_results/reversals_phase_contrast/mat_files/';
    data_name = 'manydates_Strains_1765_1770_1783_1788_1789_1822_reversals_phase_contrast'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
    data_dir_name = strcat(data_dir,data_name,'.mat');
end

save_name = regexprep(data_name, '_reversals_phase_contrast','_');
load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

% Strains
Pil_types=unique([reversals_results{:,1}]);
nbr_strains = size(Pil_types,2);

%% Graph directional changes per tracking time (meaning "good" reversals and "jiggles")
figure('units','normalized','outerposition',[0 0 1/aspect 1])
leg=[]; 
for strain = 1:1:nbr_strains
    
    type=Pil_types(strain);
    leg=[leg,Pil_types(strain)];  
    
    index_type=find([reversals_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    
    if ~more_than_SIX_replicates
        colour={'k o';'b o';'g o';'r o';'m o';'c o';'y o'};
    else
        colour={'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o';'k o'};
    end
    mean_pile=[];
    
    tracks_total = 0;
    for rep = 1:1:nbr_replicates
        r=sum(reversals_results{index_type(rep), 2}(:,3)); % # of all reversals
        j=sum(reversals_results{index_type(rep), 2}(:,4)); % # of all reversals
        t=sum(reversals_results{index_type(rep),2}(:,2))/3600; % #tracking time in hours
        c=sum(reversals_results{index_type(rep), 2}(:,5)); % # of all cells that are either reversing or jiggling
        
        rmsd = median([reversals_results{index_type(rep),3}{:,5}]);
        
        tracks_total_day = sum(reversals_results{index_type(rep), 2}(:,6)); % # of all motile cell tracks
        tracks_total = tracks_total+tracks_total_day;
        
        reversals_results{index_type(rep), 6} = (r+j)/t; % reversal rate of replicate 
        reversals_results{index_type(rep), 7} = rmsd; % median rmsd of replicate 
        
        if reversals_only
            what_to_plot = r/t; % plot reversals
        end
        if jiggles_only
            what_to_plot = j/t; % plot jiggles
        end
        if reversals_jiggles
            what_to_plot = (r+j)/t; % plot reversals + jiggles
        end
        
        if number_cells_revjiggling
        	what_to_plot = c/tracks_total_day; % plot number of cells that are either reversing or jiggling
        end
        
        if rmsd_only
        	what_to_plot = rmsd; % plot root mean square displacement
        end
        
        if rev_rmsd
            what_to_plot = ((r+j)/t) / rmsd; % plot reversals corrected by root mean square displacement
        end
        
        hold on
        plot(strain,what_to_plot,colour{rep},'Linewidth',2)
        if plot_num_tracks
            text(strain+0.3,what_to_plot,num2str(tracks_total_day));
        end
        mean_pile=[mean_pile,what_to_plot];
        
    end
%     if plot_num_tracks
        text(strain,y_revs/75,num2str(tracks_total),'Rotation', 90);
%     end
    N = size(mean_pile,2);
    avg = mean(mean_pile);                                                  % calculate mean of the reversal rates        
    plot([strain-0.1 strain+0.1],[avg avg],'k-','Linewidth',2)
    
    if plot_CI95
        SEM = std(mean_pile)/sqrt(N);                                           % calculate standard error of the reversal rates
        stdD = std(mean_pile);
        CI95_base = tinv([0.025 0.975], N-1);                                   % Calculate 95% Probability Intervals Of t-Distribution
        CI95 = bsxfun(@times, SEM, CI95_base(:));                               % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
        CIbs = bootci(50,{@mean,mean_pile},'Alpha',0.01);                        % Calculate bullsh ... I mean bootstrap 95% confidence interval, not sure what @mean does exactly
            
        if plot_bs
            plot([strain+0.12 strain+0.12], [CIbs(1) CIbs(2)],'k-','Linewidth',1)
            text(strain+0.2, avg,'bs 99% CI','Rotation', 90,'HorizontalAlignment','center')
        else
            plot([strain+0.12 strain+0.12], [avg+CI95(1) avg+CI95(2)],'k-','Linewidth',1)
            text(strain+0.2, avg,'95% CI','Rotation', 90,'HorizontalAlignment','center')
        end
    end
    if plot_stdev
        plot([strain-0.12 strain-0.12], [avg+stdD avg-stdD],'k-','Linewidth',1)
        text(strain-0.2, avg,'stdev','Rotation', 90,'HorizontalAlignment','center')
    end
end

title(title_graph)
xticks([0:1:nbr_strains+1])
ylim([0 y_revs]);
xlim([0 nbr_strains+1]);
set(gca, 'XTickLabel',{' ',leg{1,1:1:nbr_strains}}, 'Fontsize',15,'TickLabelInterpreter','none')
xtickangle(20)
if number_cells_revjiggling
    ylabel('Number of cells reversing normalized by total cells')
elseif rmsd_only
    ylabel('RMSD [µm]')
elseif rev_rmsd
    ylabel('Reversal rate [1/h] / RMSD [µm]')
else
    ylabel('Number of directional changes / tracking time [1/h]')
end

graph_type = 'reversals_phase_contrast';
if save_graphs
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files/',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files/',save_name,graph_type,'.svg'));
end
