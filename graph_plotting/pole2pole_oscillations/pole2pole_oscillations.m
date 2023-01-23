close all
clear all

%% Pre-run Settings
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'G:\Marco\bs_Twitch_results\pole2pole_oscillations\';

%% Enter dreams, desires and wishes

combined = 1;    move = 0; % both 0 for non-moving
filtered = 0; % filters out pole2pole switches that occur in subsequent frames, i.e. that last just one frame

time_early = "10min"; %"10min"; % has to match the "early" interval
time_late = "70min"; %"60min"; % has to match the "late" interval

y_ax_hist = 1; % sets the y axis of the histrograms
y_ax_freq = 4; % sets the y axis of the total frequency plot and per cell frequency plot

only_plot = 0; % if 0 reads, analyses and saves before plotting
do_save = 0; % if 0, doesn't save the graphs

% decide which plots to plot and save
plot_histograms = 1;
plot_fracosc = 1;
plot_freqtot = 1;
plot_freqcellmean = 0;

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_pole2pole_oscillations(combined,move,filtered,save_dir);
else
    data_dir = 'G:\Marco\bs_Twitch_results\pole2pole_oscillations\mat_files\';
    data_name = 'file name'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
    data_dir_name = strcat(data_dir,data_name,'.mat');
end

save_name = regexprep(data_name, '_pole2pole_oscillations','_');
load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

Pil_types_unique = unique(pole2pole_data(:,1));
nbr_PTU = size(Pil_types_unique,1);

%% Set Histogram of number of pole2pole switches for each cell track normalized by time in minute (i.e. X siwtches per min)

% generate correct X axis labels
max_value = 10;
% bin_size = 21;
% bins = linspace(0,max_value,bin_size);
bins = [0 0.1 linspace(1,10,10)];
bin_size = size(bins,2);
bin_labels = cell(1,bin_size-1);
for i = 1:bin_size-1
    bin_labels{i} = strcat(num2str(bins(i))," - ",num2str(bins(i+1)));
end
%% New better way to plot stuff
% plot detailed histograms
if plot_histograms
    figure('units','normalized','outerposition',[0 0 1 1])
    off = 0;
    colour = ["b","g","r","k","c","m"];
    colour_lolo = ["r","k","c","m","b","g"];
    for type=1:1:nbr_PTU
        off = off+1;
        Pil_type = Pil_types_unique{type};
        Pil_type_number = extractBefore(Pil_type,find(isstrprop(Pil_type,'digit')==0,1));
        index_type = find(contains(pole2pole_data(:,1), Pil_types_unique{type}));
        index_early = index_type(find(contains(pole2pole_data(index_type,3), time_early)));
        index_late = index_type(find(contains(pole2pole_data(index_type,3), time_late)));

        % collect data
        data_10min = [];
        for rep=1:1:size(index_early,1)
            data_10min = [data_10min; pole2pole_data{index_early(rep),7}(:,1)];
        end
        data_60min = [];
        for rep=1:1:size(index_late,1)
            data_60min = [data_60min; pole2pole_data{index_late(rep),7}(:,1)];
        end

        % plot histogram 10 min (normalized by sample size)
        [N,edges]=histcounts(data_10min,bins);
        total=sum(N);
        normalizedN=N/total;
        subplot(2,nbr_PTU,off)

        bar(normalizedN,colour(type))
        axis([0 bin_size 0 y_ax_hist])
        title(strcat(Pil_type_number," | ", time_early), 'Interpreter', 'none')
        set(gca, 'XTickLabel',["",[bin_labels{1:end}]], 'Fontsize',10)
        xticks([0:bin_size])
        xtickangle(45)
        xlabel("Number of bright pole switches per min (individual cell tracks, unfiltered, normalized)")
        ylabel("Probability")

        % plot histogram 60 min (normalized by sample size) 
        [N,edges]=histcounts(data_60min,bins);
        total=sum(N);
        normalizedN=N/total;
        subplot(2,nbr_PTU,off+nbr_PTU)

        bar(normalizedN,colour(type))
        axis([0 bin_size 0 y_ax_hist])
        title(strcat(Pil_type_number," | ", time_late), 'Interpreter', 'none')
        set(gca, 'XTickLabel',["",[bin_labels{1:end}]], 'Fontsize',10)
        xticks([0:bin_size])
        xtickangle(45)
        xlabel("Number of bright pole switches per min (individual cell tracks, unfiltered, normalized)")
        ylabel("Probability")     
    end
    if do_save
        graph_type = 'pole2pole_osc_hist';
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
end

% plot only fraction of cells with oscillations
if plot_fracosc
    figure('units','normalized','outerposition',[0 0 1/2 1])
    hold on
    xlabels = [];
    pos = 0;
    colour = ["b","g","r","k","c","m"];
    marker = [" o"," s"," x"," +"," *"," v", " o"," s"," x"," +"," *"," v", " o"," s"," x"," +"," *"," v", " o"," s"," x"," +"," *"," v"];
    %marker = [" o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"];
    for type=1:1:nbr_PTU
        Pil_type = Pil_types_unique{type};
        Pil_type_number = extractBefore(Pil_type,find(isstrprop(Pil_type,'digit')==0,1));
        index_type = find(contains(pole2pole_data(:,1), Pil_types_unique{type}));
        index_early = index_type(find(contains(pole2pole_data(index_type,3), time_early)));
        index_late = index_type(find(contains(pole2pole_data(index_type,3), time_late)));

        xlabels = [xlabels; strcat(Pil_type_number," | ", time_early); strcat(Pil_type_number," | ", time_late)];

        % plot early
        pos = pos+1;
        collect_mean = [];
        for rep=1:1:size(index_early,1)
            what2plot = (1-pole2pole_data{index_early(rep),10})*100;
            plot(pos,what2plot,strcat(colour(type),marker(rep)),'MarkerSize',10, 'Linewidth',2);
            collect_mean = [collect_mean;what2plot];
        end
        if size(index_early,1)>1
            plot([pos-0.1 pos+0.1], [mean(collect_mean(:,1)) mean(collect_mean(:,1))], 'k -', 'Linewidth',2);
        end

        %plot late
        pos = pos+1;
        collect_mean = [];
        for rep=1:1:size(index_late,1)
            what2plot = (1-pole2pole_data{index_late(rep),10})*100;
            plot(pos,what2plot,strcat(colour(type),marker(rep)),'MarkerSize',10, 'Linewidth',2);
            collect_mean = [collect_mean;what2plot];
        end
        if size(index_late,1)>1
            plot([pos-0.1 pos+0.1], [mean(collect_mean(:,1)) mean(collect_mean(:,1))], 'k -', 'Linewidth',2);
        end
    end
    axis([0 pos+1 0 100])
    set(gca, 'XTickLabel',["";xlabels;""], 'Fontsize',10, 'TickLabelInterpreter','none')
    xticks([0:pos+1])
    xtickangle(45)
    ylabel("Fraction of cells with bright pole switches (%)")
    
    if do_save
        graph_type = 'pole2pole_osc_frac';
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
end

%% plot average oscillation frequency per min (over all cell tracks)
if plot_freqtot
    figure('units','normalized','outerposition',[0 0 1/2 1])
    hold on
    xlabels = [];
    pos = 0;
    colour = ["b","g","r","k","c","m"];
    marker = [" o"," s"," x"," +"," *"," v","d","h"];
%     marker = [" o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"];
    for type=1:1:nbr_PTU
        Pil_type = Pil_types_unique{type};
        Pil_type_number = extractBefore(Pil_type,find(isstrprop(Pil_type,'digit')==0,1));
        index_type = find(contains(pole2pole_data(:,1), Pil_types_unique{type}));
        index_early = index_type(find(contains(pole2pole_data(index_type,3), time_early)));
        index_late = index_type(find(contains(pole2pole_data(index_type,3), time_late)));

        xlabels = [xlabels; strcat(Pil_type_number," | ", time_early); strcat(Pil_type_number," | ", time_late)];

        % plot early
        pos = pos+1;
        collect_mean = [];
        for rep=1:1:size(index_early,1)
            what2plot = pole2pole_data{index_early(rep),6};
            plot(pos,what2plot,strcat(colour(type),marker(rep)),'MarkerSize',10, 'Linewidth',2);
            collect_mean = [collect_mean;what2plot];
        end
        if size(index_early,1)>1
            plot([pos-0.1 pos+0.1], [mean(collect_mean(:,1)) mean(collect_mean(:,1))], 'k -', 'Linewidth',2);
        end

        % plot late
        pos = pos+1;
        collect_mean = [];
        for rep=1:1:size(index_late,1)
            what2plot = pole2pole_data{index_late(rep),6};
            plot(pos,what2plot,strcat(colour(type),marker(rep)),'MarkerSize',10, 'Linewidth',2);
            collect_mean = [collect_mean;what2plot];
        end
        if size(index_late,1)>1
            plot([pos-0.1 pos+0.1], [mean(collect_mean(:,1)) mean(collect_mean(:,1))], 'k -', 'Linewidth',2);
        end
    end

    axis([0 pos+1 0 y_ax_freq])
    set(gca, 'XTickLabel',["";xlabels;""], 'Fontsize',10, 'TickLabelInterpreter','none')
    xticks([0:pos+1])
    xtickangle(45)
    ylabel("Frequency bright pole switches (1/min) [all switches/all time tracked]")
    
    if do_save
        graph_type = 'pole2pole_osc_freqtot';
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
end

%% plot average oscillation frequency per min (Mean for each cell track)
if plot_freqcellmean
    figure('units','normalized','outerposition',[0 0 1/2 1])
    hold on
    xlabels = [];
    pos = 0;
    colour = ["b","g","r","k","c","m"];
    % marker = [" o"," s"," x"," +"," *"," v","d","h"];
    marker = [" o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"," o"];
    for type=1:1:nbr_PTU
        Pil_type = Pil_types_unique{type};
        Pil_type_number = extractBefore(Pil_type,find(isstrprop(Pil_type,'digit')==0,1));
        index_type = find(contains(pole2pole_data(:,1), Pil_types_unique{type}));
        index_early = index_type(find(contains(pole2pole_data(index_type,3), time_early)));
        index_late = index_type(find(contains(pole2pole_data(index_type,3), time_late)));

        xlabels = [xlabels; strcat(Pil_type_number," | ", time_early); strcat(Pil_type_number," | ", time_late)];

        % plot early
        pos = pos+1;
        collect_mean = [];
        for rep=1:1:size(index_early,1)
            what2plot = pole2pole_data{index_early(rep),8};
            plot(pos,what2plot,strcat(colour(type),marker(rep)),'MarkerSize',10, 'Linewidth',2);
            collect_mean = [collect_mean;what2plot];
        end
        if size(index_early,1)>1
            plot([pos-0.1 pos+0.1], [mean(collect_mean(:,1)) mean(collect_mean(:,1))], 'k -', 'Linewidth',2);
        end

        % plot late
        pos = pos+1;
        collect_mean = [];
        for rep=1:1:size(index_late,1)
            what2plot = pole2pole_data{index_late(rep),8};
            plot(pos,what2plot,strcat(colour(type),marker(rep)),'MarkerSize',10, 'Linewidth',2);
            collect_mean = [collect_mean;what2plot];
        end
        if size(index_late,1)>1
            plot([pos-0.1 pos+0.1], [mean(collect_mean(:,1)) mean(collect_mean(:,1))], 'k -', 'Linewidth',2);
        end
    end

    axis([0 pos+1 0 y_ax_freq])
    set(gca, 'XTickLabel',["";xlabels;""], 'Fontsize',10, 'TickLabelInterpreter','none')
    xticks([0:pos+1])
    xtickangle(45)
    ylabel("Frequency bright pole switches (1/min) [Mean per cell track]")
    
    if do_save
        graph_type = 'pole2pole_osc_freqcellmean';
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
end