%% Plots direction-corrected displacement

% also adds columns to real_displacement_results.mat, but doesn't save it

    % adds column 4 and 5 to cell with 3 columns and column 5 to cell in column 3
        % 1: Pil_type
        % 2: date
        % 3: cell with 4 columns of displacement and speed data
            % 1: bact_id (which really is the id of the track; one cell can have multiple track ids!
            % 2: length of track (in timepoints)
            % 3: direction-corrected displacement in µm (using non-speed-filtered displacement and rounded alignment factor of unitary speed and unitary cell direction vector)
            % 4: filtered speed in µm/s for each timepoint of the track (thresholded for speed limit in BacStalk code)
            % 5: median speed over all timepoints (only using timepoints with speed above speed limit)
        % 4: number of tracks that meet the conditions set below (min and max tracked)
        % 5: median of column 5 of cell in column 3

% only works if all listed strains were analysed with the save_real_displacement_MJK.m script
% !!! only works with 3 repslicates max !!!

clear all
close all

%% Pre-run Settings
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'G:\Marco\bs_Twitch_results\displacement_maps_speed\';

only_plot = 0; % if 0 reads, analyses and saves before plotting

%% Run save function
addpath('functions');
if ~only_plot
    [data_dir_name, data_name] = save_displacement_maps(save_dir);
else
    data_dir = 'C:\Users\mkuehn\git\bs_Twitch\results\displacement_maps_speed\mat_files\';
    data_name = '20220726_20220728_20220729_20220804_Strains_1634_1635_1638_displacement_maps_speed'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
    data_dir_name = strcat(data_dir,data_name,'.mat');
end

save_name = regexprep(data_name, '_displacement_maps_speed','_');
load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

%% set options

tos = "2h";
IntervalTime = 5; % in sec

min_tracked = 10; % minimum frames that cell must be tracked to be considered, for typical 5min-5s movies 31 is ok
max_tracked = 20; % maximum frames that cell can be tracked to be considered, for typical 5min-5s movies 61 is the max

desired_tracks = 50; % maximum number of tracks to plot. if less tracks in real_displacement_results, takes max available

plot_speed_cut = 1; % Note, plots speed of tracked-frame-thresholded tracks!
plot_speed_all = 1; % Note, plots speed of all cells
plot_violin = 1;
plot_histograms = 0;
plot_maps = 1;

y_speed = 0.5;  % y-axis of speed plots
scaling_violin = 0.05; % scaling width of violin plots

xLo = -10; xHi = 20; yLo = 0; yHi = 70; % scaling of displacement map plots, for typical 5min-5s movies 150 is ok

aspect_maps = 1; % 1/aspect_maps = width of the displacement maps
aspect_speed = 2; % 1/aspect_speed = width of the speed plot

display_track_num = 0; % if set to 1 displays the track number of plotted track. only use if plitting one by one using the interrupt dots to find a certrain track number. Note, look in the "real_displacement_results" cell to find the track number and estimate which movie number it is!

% Strains
Pil_types=unique([real_displacement_results{:,1}]);
nbr_strains = size(Pil_types,2);

% load functions
addpath(strcat(dir_func,'Functions')); 

% Diagram
colour = ["k","r","b","g","c","m","y"];

%% Process data for all tracks (normaize by speed, ...)
leg=[];
all_speeds = cell(nbr_strains,4);

for strain = 1:1:nbr_strains
    
    type=Pil_types(strain);
    leg=[leg,Pil_types(strain)];  
    
    index_type=find([real_displacement_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    is_emtpy = zeros(nbr_replicates,1);
    for rep = 1:1:nbr_replicates
        if isempty(real_displacement_results{index_type(rep),3})
            is_emtpy(rep) = 1;
        else
            is_emtpy(rep) = 0;
        end
    end
    index_empty = find(is_emtpy);
    if ~isempty(index_empty)
        real_displacement_results(index_type(index_empty),:)=[];
    end
    
    % get median (filtered) speed
    if plot_histograms
        if plot_speed_cut
            figure
            title(type)
        end
    end
    
    speeds_concat = [];
    date_concat = [];
    for rep = 1:1:nbr_replicates
        if iscell(real_displacement_results{index_type(rep),3})
            tracks_total = size(real_displacement_results{index_type(rep),3},1);
            for track = 1:1:tracks_total
                rows_speed = [real_displacement_results{index_type(rep),3}{track,4}(:,1)]>0;
                index_rows_speed = find(rows_speed==1);
                % now calculate median of speed for this track over all timepoints with significant speed  (i.e. above speed limit defined in analyse_single_video)
                real_displacement_results{index_type(rep), 3}{track, 5} = median(real_displacement_results{index_type(rep),3}{track,4}(index_rows_speed,1));
            end
                
        % plot histogramm of median speed of each track
        if plot_histograms
            if plot_speed_cut
                hold on
                histogram([real_displacement_results{index_type(rep),3}{:,5}],'Binwidth',0.01)
            end
        end

        % for each replicate, calculate median speed of median speeds over all tracks
        real_displacement_results{index_type(rep),5} = median([real_displacement_results{index_type(rep),3}{:,5}]);
        
        % concatenate the median speeds for al tracks for all replicates
        % also all dates
        speeds_concat = [speeds_concat,real_displacement_results{index_type(rep), 3}{:, 5}];
        date_concat = [date_concat;real_displacement_results{rep, 2}];
        end
    end
all_speeds{strain,1} = type;
all_speeds{strain,2} = date_concat;
all_speeds{strain,3} = speeds_concat;
all_speeds{strain,4} = size(speeds_concat,2);
end

%% Plot speed all tracks

if plot_speed_all
    figure('units','normalized','outerposition',[0 0 1/aspect_speed 1])
    axis([0 nbr_strains+1 0 y_speed])
    hold on
    set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
    xticks([0:1:nbr_strains+1])
    xtickangle(15)
    ylabel("Twitching Speed (µm/s)")

%         colour_speed = ["r o","b o","g o","k o","c o","m o","y o"];
    colour_speed = ["k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o"];

    x_val = [];
    for strain = 1:1:nbr_strains

        type=Pil_types(strain);
        index_type=find([real_displacement_results{:,1}]==type);
        nbr_replicates = size(index_type,2);

        x_val = [x_val,strain];
        for rep = 1:1:nbr_replicates
            if ~isempty(real_displacement_results{index_type(rep),3})
                plot(x_val(strain),real_displacement_results{index_type(rep),5},colour_speed(rep),'MarkerSize',8,'Linewidth',1)
            end
        end
        mean_speed = mean([real_displacement_results{index_type,5}]);        
        plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_speed mean_speed],'k -','Linewidth',3)
%         text(x_val(strain)-0.2, mean_speed, num2str(all_speeds{strain,4}), 'HorizontalAlignment','right');
        text(x_val(strain), 0.005, num2str(all_speeds{strain,4}), 'HorizontalAlignment','center');
        if plot_violin
            violin(x_val(strain), all_speeds{strain,3},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin)
        end
    end
    title("All tracks, no length limit");
    
    graph_type = 'speed_all';
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
end

%% Process data for filterd tracks (filter for track time length, normaize by speed, ...)
leg=[];
all_speeds = cell(nbr_strains,4);

for strain = 1:1:nbr_strains
        
    type=Pil_types(strain);
    leg=[leg,Pil_types(strain)];  

    index_type=find([real_displacement_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    is_emtpy = zeros(nbr_replicates,1);
    for rep = 1:1:nbr_replicates
        if isempty(real_displacement_results{index_type(rep),3})
            is_emtpy(rep) = 1;
        else
            is_emtpy(rep) = 0;
        end
    end
    index_empty = find(is_emtpy);
    if ~isempty(index_empty)
        real_displacement_results(index_type(index_empty),:)=[];
    end
    
        
    % delete rows that don't fit condition of min tracked time
    index_type=find([real_displacement_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    for rep = 1:1:nbr_replicates
        rows_del = [real_displacement_results{index_type(rep),3}{:,2}]<min_tracked;
        rows_del_max = [real_displacement_results{index_type(rep),3}{:,2}]>max_tracked;
        index_rows_delete = [find(rows_del==1),find(rows_del_max==1)];
        real_displacement_results{index_type(rep),3}(index_rows_delete,:)=[];
        real_displacement_results{index_type(rep),4} = size(real_displacement_results{index_type(rep),3},1);
    end    
    
    % get median (filtered) speed
    if plot_histograms
        if plot_speed_cut
            figure
            title(type)
        end
    end
    
    speeds_concat = [];
    date_concat = [];
    for rep = 1:1:nbr_replicates
        if iscell(real_displacement_results{index_type(rep),3})
            tracks_total = real_displacement_results{index_type(rep),4};
            for track = 1:1:tracks_total
                rows_speed = [real_displacement_results{index_type(rep),3}{track,4}(:,1)]>0;
                index_rows_speed = find(rows_speed==1);
                % now calculate median of speed for this track over all timepoints with significant speed  (i.e. above speed limit defined in analyse_single_video)
                real_displacement_results{index_type(rep), 3}{track, 5} = median(real_displacement_results{index_type(rep),3}{track,4}(index_rows_speed,1));
            end
                
        % plot histogramm of median speed of each track
        if plot_histograms
            if plot_speed_cut
                hold on
                histogram([real_displacement_results{index_type(rep),3}{:,5}],'Binwidth',0.01)
            end
        end
        
        % for each replicate, calculate median speed of median speeds over all tracks
        real_displacement_results{index_type(rep),5} = median([real_displacement_results{index_type(rep),3}{:,5}]);
        
        % concatenate the median speeds for al tracks for all replicates
        % also all dates
        speeds_concat = [speeds_concat,real_displacement_results{index_type(rep), 3}{:, 5}];
        date_concat = [date_concat;real_displacement_results{rep, 2}];
        end
    end
all_speeds{strain,1} = type;
all_speeds{strain,2} = date_concat;
all_speeds{strain,3} = speeds_concat;
all_speeds{strain,4} = size(speeds_concat,2);
end


%% Plot speed

if plot_speed_cut
    figure('units','normalized','outerposition',[0 0 1/2 1])
    axis([0 nbr_strains+1 0 y_speed])
    hold on
    set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
    xticks([0:1:nbr_strains+1])
    xtickangle(15)
    ylabel("Twitching Speed (µm/s)")

%         colour_speed = ["r o","b o","g o","k o","c o","m o","y o"];
    colour_speed = ["k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o","k o"];

    x_val = [];
    for strain = 1:1:nbr_strains

        type=Pil_types(strain);
        index_type=find([real_displacement_results{:,1}]==type);
        nbr_replicates = size(index_type,2);

        x_val = [x_val,strain];
        for rep = 1:1:nbr_replicates
            if ~isempty(real_displacement_results{index_type(rep),3})
                plot(x_val(strain),real_displacement_results{index_type(rep),5},colour_speed(rep),'MarkerSize',8,'Linewidth',1)
            end
        end
        mean_speed = mean([real_displacement_results{index_type,5}]);
        plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_speed mean_speed],'k -','Linewidth',3)
%         text(x_val(strain)-0.2, mean_speed, num2str(all_speeds{strain,4}), 'HorizontalAlignment','right');
        text(x_val(strain), 0.005, num2str(all_speeds{strain,4}), 'HorizontalAlignment','center');
        if plot_violin
            if ~isempty(all_speeds{strain,3})
                violin(x_val(strain), all_speeds{strain,3},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin)
            else
                disp(strcat("WARNING, Speed: It seems like there are no tracks left for strain ",type," using the current min_tracked / max_tracked values!"));
            end
        end
    end
    title(strcat("Filtered tracks, minimum length: ", num2str(min_tracked), " frames"));
    
    graph_type = 'speed_cut';
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
end

%% Plot displacements

if plot_maps
    figure('units','normalized','outerposition',[0 0 1 aspect_maps])

    p = 0;

    for strain = 1:1:nbr_strains

        type=Pil_types(strain);
        index_type=find([real_displacement_results{:,1}]==type);
        nbr_replicates = size(index_type,2);
        rep_ind = repmat([1:nbr_replicates],1,1000);

        tracks_total = sum([real_displacement_results{index_type,4}]);
        if tracks_total<desired_tracks
            max_tracks = tracks_total;
        elseif tracks_total>=desired_tracks
            max_tracks = desired_tracks;
        end

        p = p+1;
    %     subplot(nbr_strains/2,2,p)
        subplot(nbr_strains,1,p)
    %     figure('units','normalized','outerposition',[0 0 1 1])
        title(strcat("Time on surface: ",tos,"   ","Range: ",num2str((min_tracked-1)*IntervalTime),"-",num2str((max_tracked-1)*IntervalTime),"s   ","Tracks: ",num2str(max_tracks)))
        if max_tracks==0
           disp(strcat("WARNING, Displacement Maps: It seems like there are no tracks left for strain ",type," using the current min_tracked / max_tracked values!")); 
        end
    %     axis([-45 75 0 (max_tracked-1)*5])
        axis([xLo xHi yLo yHi])
        hold on

        track_rep = [0,0,0];
        index_max_rep = find([real_displacement_results{index_type,4}]==max([real_displacement_results{index_type,4}]));

        for plot_nbr = 1:1:max_tracks

            if rep_ind(plot_nbr)==1
                if track_rep(rep_ind(plot_nbr))<size(real_displacement_results{index_type(rep_ind(plot_nbr)),3},1)
                    plotted_rep = rep_ind(plot_nbr);
                    track_rep(rep_ind(plot_nbr)) = track_rep(rep_ind(plot_nbr))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                elseif track_rep(rep_ind(plot_nbr+1))<size(real_displacement_results{index_type(rep_ind(plot_nbr+1)),3},1) & plotted_rep~=2
                    plotted_rep = rep_ind(plot_nbr+1);
                    track_rep(rep_ind(plot_nbr+1)) = track_rep(rep_ind(plot_nbr+1))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr+1)),3}{track_rep(rep_ind(plot_nbr+1)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr+1)),3}{track_rep(rep_ind(plot_nbr+1)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr+1)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                elseif track_rep(rep_ind(plot_nbr+2))<size(real_displacement_results{index_type(rep_ind(plot_nbr+2)),3},1) & plotted_rep~=3
                    plotted_rep = rep_ind(plot_nbr+2);
                    track_rep(rep_ind(plot_nbr+2)) = track_rep(rep_ind(plot_nbr+2))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr+2)),3}{track_rep(rep_ind(plot_nbr+2)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr+2)),3}{track_rep(rep_ind(plot_nbr+2)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr+2)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                else
                    plotted_rep = rep_ind(index_max_rep);
                    track_rep(rep_ind(index_max_rep)) = track_rep(rep_ind(index_max_rep))+1;

                                    max_time = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),1};
                    track_date = real_displacement_results{index_type(rep_ind(index_max_rep)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)
                end
            end

            if rep_ind(plot_nbr)==2

                if track_rep(rep_ind(plot_nbr))<size(real_displacement_results{index_type(rep_ind(plot_nbr)),3},1) & plotted_rep~=2
                    plotted_rep = rep_ind(plot_nbr);
                    track_rep(rep_ind(plot_nbr)) = track_rep(rep_ind(plot_nbr))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                elseif track_rep(rep_ind(plot_nbr+1))<size(real_displacement_results{index_type(rep_ind(plot_nbr+1)),3},1) & plotted_rep~=3
                    plotted_rep = rep_ind(plot_nbr+1);
                    track_rep(rep_ind(plot_nbr+1)) = track_rep(rep_ind(plot_nbr+1))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr+1)),3}{track_rep(rep_ind(plot_nbr+1)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr+1)),3}{track_rep(rep_ind(plot_nbr+1)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr+1)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                elseif track_rep(rep_ind(plot_nbr-1))<size(real_displacement_results{index_type(rep_ind(plot_nbr-1)),3},1) & plotted_rep~=1
                    plotted_rep = rep_ind(plot_nbr-1);
                    track_rep(rep_ind(plot_nbr-1)) = track_rep(rep_ind(plot_nbr-1))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr-1)),3}{track_rep(rep_ind(plot_nbr-1)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr-1)),3}{track_rep(rep_ind(plot_nbr-1)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr-1)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                else
                    plotted_rep = rep_ind(index_max_rep);
                    track_rep(rep_ind(index_max_rep)) = track_rep(rep_ind(index_max_rep))+1;

                    max_time = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),1};
                    track_date = real_displacement_results{index_type(rep_ind(index_max_rep)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                end
            end

            if rep_ind(plot_nbr)==3

                if track_rep(rep_ind(plot_nbr))<size(real_displacement_results{index_type(rep_ind(plot_nbr)),3},1) & plotted_rep~=3
                    plotted_rep = rep_ind(plot_nbr);
                    track_rep(rep_ind(plot_nbr)) = track_rep(rep_ind(plot_nbr))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                elseif track_rep(rep_ind(plot_nbr-2))<size(real_displacement_results{index_type(rep_ind(plot_nbr-2)),3},1) & plotted_rep~=1
                    plotted_rep = rep_ind(plot_nbr-2);
                    track_rep(rep_ind(plot_nbr-2)) = track_rep(rep_ind(plot_nbr-2))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr-2)),3}{track_rep(rep_ind(plot_nbr-2)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr-2)),3}{track_rep(rep_ind(plot_nbr-2)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr-2)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                elseif track_rep(rep_ind(plot_nbr-1))<size(real_displacement_results{index_type(rep_ind(plot_nbr-1)),3},1) & plotted_rep~=2
                    plotted_rep = rep_ind(plot_nbr-1);
                    track_rep(rep_ind(plot_nbr-1)) = track_rep(rep_ind(plot_nbr-1))+1;

                    max_time = real_displacement_results{index_type(rep_ind(plot_nbr-1)),3}{track_rep(rep_ind(plot_nbr-1)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(plot_nbr-1)),3}{track_rep(rep_ind(plot_nbr-1)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(plot_nbr-1)),3}{track_rep(rep_ind(plot_nbr)),1};
                    track_date = real_displacement_results{index_type(rep_ind(plot_nbr)),2};                 
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)

                else
                    plotted_rep = rep_ind(index_max_rep);
                    track_rep(rep_ind(index_max_rep)) = track_rep(rep_ind(index_max_rep))+1;

                    max_time = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),2};
                    y_values = IntervalTime*[0:max_time-1]'; 

                    disp_directional = [0:max_time-1]';
                    for t = 2:1:max_time
                        disp_directional(t,1) = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),3}(t,1) + disp_directional(t-1,1);
                    end
                    track_number = real_displacement_results{index_type(rep_ind(index_max_rep)),3}{track_rep(rep_ind(index_max_rep)),1};
                    track_date = real_displacement_results{index_type(rep_ind(index_max_rep)),2};
                    if display_track_num
                        disp(strcat("Date: ", num2str(track_date), " Track: ", num2str(track_number)))
                    end

                    plot(disp_directional,y_values,colour(strain),'LineWidth',1)      
                end
            end

        end
        dummy(strain) = plot(nan, nan, colour(strain),'Linewidth',2);
    end
    legend(dummy,leg,'Fontsize',15,'Interpreter','none')
    ylabel('Time (s)')
    xlabel('Displacement (µm)')
    
    graph_type = 'displacement_maps';
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
end