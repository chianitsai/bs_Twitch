%% Plot  reversal frequency of single twitching cells (phase contrast only)
clear all
close all

%% Pre-run Settings
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'G:\Marco\bs_Twitch_results\reversals_phase_contrast\';

%% To modify:
title_graph="Time on surface = 2h"; %    Min limit time=2   Reversal time=5';

y_revs = 55;
y_ratio = 1;
aspect = 3; % divides the figure width (normally screen width) by given number
plot_CI95 = 1; 
    plot_bs = 0; % decide if plotting "normal" CI95 or bootstrap CI95
plot_stdev = 1; 
plot_num_tracks = 1;

more_than_SIX_replicates = 0; % if more than 6 replicates the colours are all black, if not set to 1 produces error

only_plot = 1; % if 0 reads, analyses and saves before plotting

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_reversals_phase_contrast(save_dir);
else
    data_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\reversals_phase_contrast\mat_files\';
    data_name = '20220726_20220728_20220729_20220804_Strains_1634_1635_1638_reversals_phase_contrast'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
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
    
    for rep = 1:1:nbr_replicates
        r=sum(reversals_results{index_type(rep), 2}(:,3)); % # of all reversals
        j=sum(reversals_results{index_type(rep), 2}(:,4)); % # of all reversals
        t=sum(reversals_results{index_type(rep),2}(:,2))/3600; % #tracking time in hours
        
        tracks_total_day = sum(reversals_results{index_type(rep), 2}(:,6)); % # of all motile cell tracks
        
        hold on
        plot(strain,(r+j)/t,colour{rep},'Linewidth',2)
        if plot_num_tracks
            text(strain+0.3,(r+j)/t,num2str(tracks_total_day));
        end
        mean_pile=[mean_pile,(r+j)/t];
        
    end
    
    N = size(mean_pile,2);
    avg = mean(mean_pile);                                                  % calculate mean of the reversal rates
    SEM = std(mean_pile)/sqrt(N);                                           % calculate standard error of the reversal rates
    stdD = std(mean_pile);
    CI95_base = tinv([0.025 0.975], N-1);                                   % Calculate 95% Probability Intervals Of t-Distribution
    CI95 = bsxfun(@times, SEM, CI95_base(:));                               % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
    CIbs = bootci(50,{@mean,mean_pile},'Alpha',0.01);                        % Calculate bullsh ... I mean bootstrap 95% confidence interval, not sure what @mean does exactly
    
    plot([strain-0.1 strain+0.1],[avg avg],'k-','Linewidth',2)
    if plot_CI95
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
ylabel('# Directional changes / Tracking time [1/h]')

graph_type = 'reversals_phase_contrast';
saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
