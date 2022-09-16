%% Plots speed, polar localization motile average index and polar localization vs speed

clear all
close all

%% Pre-run Settings
dir_func='C:\Users\mkuehn\git\bs_Twitch\';
save_dir = 'G:\Marco\bs_Twitch_results\polar_loc_speed_motile\';

only_plot = 1; % if 0 reads, analyses and saves before plotting
save_graphs = 1;
two_ch = 1; % 1 if you want to plot from two channel data, 0 uses only the first channel even if there are two

addition = '_noSL'; % filename addition of the variables.mat file: '_noSL' if speed_limit = 0
ch1 = "mNG";
ch2 = "mScI";

mean_median = 'mean'; % defines if mean or median speed over all tracked timepoints

%% Run save function
addpath('functions');
if ~only_plot
  [data_dir_name, data_name] = save_polar_loc_speed_motile(mean_median,two_ch,addition,save_dir);
else
  data_dir = strcat(save_dir,'mat_files\');
  data_name = '20220728_20220729_20220812_20220825_Strains_1633_polar_loc_speed_motile_noSL'; % if only_plot = 1 copy the name of the mat file you want to plot WITHOUT .mat
  data_dir_name = strcat(data_dir,data_name,'.mat');
end

save_name = regexprep(data_name, strcat('_polar_loc_speed_motile',addition),'_');
load(data_dir_name) % loads analysis file that was done with function "save_displacement_maps.m"

%% set options

tos = "2h";

plot_violin = 1; % plots distribution of single-track values as violin plot

plot_speed = 1; % plots speed
plot_polLoc = 1; % plots ratio polar intensity vs cytoplasm (polar localization motile index)
plot_polLoc_speed = 1; % plots polar localization motile index vs speed, single track
plot_polLoc_vs = 1; % plots polar localization motile index of channel 1 vs 2
plot_polLoc_speed_ch1polar = 1; % I wouldn't do this for more than 1 strain
plot_polLoc_vs_ch1polar = 1; % I wouldn't do this for more than 1 strain
plot_polAsym = 1; % plots the ratio of polar intensities between poles 1-(dim / bright)=Asymmetry Index
plot_polAsym_speed = 1; % plots polAsym vs speed
plot_polLoc_vs_polAsym = 1; % plots polar localization motile index of channel 1 vs asymmetry index channel 2 (speed colour-coded)

rep_colour = 1; % if replicates are coloured separately, works for max 6 replicates
type_ratio = "mean"; % "mean" or "max" or "total"

y_speed_vio = 0.1; % y-axis of speed plots 
y_polLoc_vio = 2.5; % y-axis of pole vs cytoplasm ratio plots
y_polAsym_vio = 0.9; % y-axis of polAsym plot
scaling_violin_speed = 0.02; % scaling width of violin plots
scaling_violin_polLoc = 0.2; % scaling width of violin plots

y_speed_st = 0.5; % y-axis of speed plots individual tracks
y_polLoc_st = 2.5; % y-axis of pole vs cytoplasm ratio plotsindividual tracks

no_move = 0.007; % manually entered rough threshold for non-moving cells
no_polLoc = 0.65; % manually entered rough threshold for non-polar localization
no_polAsym = 1-0.69; % manually entered rough threshold for non_asymmetric (i.e. symmetric) localization. Comes from distribution of PilB, from the first mechanotaxis paper 2021


aspect_data = 2; % 1/aspect_speed = width of the speed plot

%% Start looping

% Strains
Pil_types=unique([polar_loc_speed_motile_results{:,1}]);
nbr_strains = size(Pil_types,2);

% load functions
addpath(strcat(dir_func,'Functions')); 

% Diagram
colour_reps = ["b","g","m","c","r","y"];

%% Plot speed all tracks

if plot_speed
  figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
  axis([0 nbr_strains+2 0 y_speed_vio])
  hold on
  set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
  xticks([0:1:nbr_strains+1])
  xtickangle(15)
  ylabel("Twitching Speed (µm/s)")

  x_val = [];
  leg=[];
  for strain = 1:1:nbr_strains
    leg=[leg,Pil_types(strain)]; 
        
    type=Pil_types(strain);
    index_type=find([polar_loc_speed_motile_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    
    x_val = [x_val,strain];
    for rep = 1:1:nbr_replicates   
        if rep_colour
            if nbr_replicates<7
              marker_rep = strcat(colour_reps(rep)," o");
            else
              marker_rep = "k o";
              disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
            end
        else
            marker_rep = "k o";
        end
        
        if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
        plot(x_val(strain),polar_loc_speed_motile_results{index_type(rep),4},marker_rep,'MarkerSize',8,'Linewidth',1.5) % plots median speed of the replicate
        end
    end
    mean_data = mean([polar_loc_speed_motile_results{index_type,4}]);    
    plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean speed over all replicates 
    text(x_val(strain), 0.005, num2str(polar_loc_speed_motile_concat{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
    if plot_violin
      violin(x_val(strain), polar_loc_speed_motile_concat{strain,3},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_speed) % plots distribution of single-track values combined for all replicates
    end
  end
  
  plot([0 nbr_strains+2],[no_move no_move],'k --','Linewidth',1)
  text(0.03,no_move+0.0015,"rough no-move threshold",'FontSize',8)
  title(strcat("Cell speed after ",tos," on surface"));
  
  graph_type = strcat('speed',addition);
  if save_graphs
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
  end
end

%% Plot polar to cytoplasmic ratio all tracks channel 1 (typically mNG)

if plot_polLoc
  [type_ratio_position] = type_ratio_position_function(type_ratio);
  
  figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
  axis([0 nbr_strains+2 0 y_polLoc_vio])
  hold on
  set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
  xticks([0:1:nbr_strains+1])
  xtickangle(15)
  ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))

  x_val = [];
  leg=[];
  for strain = 1:1:nbr_strains
    leg=[leg,Pil_types(strain)]; 
        
    type=Pil_types(strain);
    index_type=find([polar_loc_speed_motile_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    
    x_val = [x_val,strain];
    for rep = 1:1:nbr_replicates
        if rep_colour
            if nbr_replicates<7
              marker_rep = strcat(colour_reps(rep)," o");
            else
              marker_rep = "k o";
              disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
            end
        else
            marker_rep = "k o";
        end
        if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
        plot(x_val(strain),polar_loc_speed_motile_results{index_type(rep),type_ratio_position(1)},marker_rep,'MarkerSize',8,'Linewidth',1.5) % plots median polar loc ratio of the replicate
        end
    end
    mean_data = mean([polar_loc_speed_motile_results{index_type,type_ratio_position(1)}]);      
    plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates 
    text(x_val(strain), 0.05, num2str(polar_loc_speed_motile_concat{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
    if plot_violin
      violin(x_val(strain), polar_loc_speed_motile_concat{strain,type_ratio_position(2)},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
    end
  end
  
  plot([0 nbr_strains+2],[no_polLoc no_polLoc],'k --','Linewidth',1)
  text(0.03,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8) % this threshold should be checked again
  title(strcat("Ratio pole / cytoplasm after ",tos," on surface"));
  
  graph_type = strcat('polLoc_ratio',addition,'_',type_ratio,'_',ch1);
  if save_graphs
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
  end
end

%% Plot polar to cytoplasmic ratio all tracks channel 2 (typically mScI)
if two_ch
  if plot_polLoc
    [type_ratio_position] = type_ratio_position_function(type_ratio);

    figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
    axis([0 nbr_strains+2 0 y_polLoc_vio])
    hold on
    set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
    xticks([0:1:nbr_strains+1])
    xtickangle(15)
    ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))

    x_val = [];
    leg=[];
    for strain = 1:1:nbr_strains
    leg=[leg,Pil_types(strain)]; 

    type=Pil_types(strain);
    index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
    nbr_replicates = size(index_type,2);

    x_val = [x_val,strain];
        for rep = 1:1:nbr_replicates
            if rep_colour
                if nbr_replicates<7
                  marker_rep = strcat(colour_reps(rep)," o");
                else
                  marker_rep = "k o";
                  disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
                end
            else
                marker_rep = "k o";
            end
            if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
              plot(x_val(strain),polar_loc_speed_motile_results_ch2{index_type(rep),type_ratio_position(1)},marker_rep,'MarkerSize',8,'Linewidth',1.5) % plots median polar loc ratio of the replicate
            end
        end
        mean_data = mean([polar_loc_speed_motile_results_ch2{index_type,type_ratio_position(1)}]);      
        plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates 
        text(x_val(strain), 0.05, num2str(polar_loc_speed_motile_concat_ch2{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
        if plot_violin
        violin(x_val(strain), polar_loc_speed_motile_concat_ch2{strain,type_ratio_position(2)},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
        end
    end

    plot([0 nbr_strains+2],[no_polLoc no_polLoc],'k --','Linewidth',1)
    text(0.03,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8) % this threshold should be checked again
    title(strcat("Ratio pole / cytoplasm after ",tos," on surface"));

    graph_type = strcat('polLoc_ratio',addition,'_',type_ratio,'_',ch2);
    if save_graphs
      saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
      saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
      saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
  end
end

%% Plot polar loc ratio vs speed channel 1 (typically mNG)
if plot_polLoc_speed
  [type_ratio_position] = type_ratio_position_function(type_ratio);
  
  for strain = 1:1:nbr_strains
    
    figure('units','normalized','outerposition',[0 0 1 1])
    axis([0 y_speed_st 0 y_polLoc_st])
    hold on
    ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))
    xlabel("Speed (µm/s)")
            
    type=Pil_types(strain);
    index_type=find([polar_loc_speed_motile_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    
    if rep_colour
      for rep = 1:1:nbr_replicates
        if nbr_replicates<7
          marker_rep = strcat(colour_reps(rep)," o");
        else
          marker_rep = "k o";
          disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
        end
        if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
          plot([polar_loc_speed_motile_results{index_type(rep),3}{:,5}],[polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1) 
        end
      end
    else
      speeds = polar_loc_speed_motile_concat{strain, 3};
      polLocs = polar_loc_speed_motile_concat{strain, type_ratio_position(2)};
      plot(speeds,polLocs,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
    end
      
    plot([0 y_speed_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
    text(y_speed_st-0.001,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again
    
    plot([no_move no_move],[0 y_polLoc_st],'k --','Linewidth',1)
    text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')
    
    title(strcat("Polar Loc vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');
    
    graph_type = strcat('polLoc_vs_speed',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch1);
    if save_graphs
      saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
      saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
      saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
  end  
end

%% Plot polar loc ratio vs speed channel 2 (typically mScI)
if two_ch
  if plot_polLoc_speed
    [type_ratio_position] = type_ratio_position_function(type_ratio);

    for strain = 1:1:nbr_strains

      figure('units','normalized','outerposition',[0 0 1 1])
      axis([0 y_speed_st 0 y_polLoc_st])
      hold on
      ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))
      xlabel("Speed (µm/s)")

      type=Pil_types(strain);
      index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
      nbr_replicates = size(index_type,2);

      if rep_colour
        for rep = 1:1:nbr_replicates
          if nbr_replicates<7
            marker_rep = strcat(colour_reps(rep)," o");
          else
            marker_rep = "k o";
            disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
          end
          if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
            plot([polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,5}],[polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1) 
          end
        end
      else
        speeds = polar_loc_speed_motile_concat_ch2{strain, 3};
        polLocs = polar_loc_speed_motile_concat_ch2{strain, type_ratio_position(2)};
        plot(speeds,polLocs,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
      end

      plot([0 y_speed_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
      text(y_speed_st-0.001,no_polLoc+0.04,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again

      plot([no_move no_move],[0 y_polLoc_st],'k --','Linewidth',1)
      text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')

      title(strcat("Polar Loc vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');

      graph_type = strcat('polLoc_vs_speed',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch2);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end
    end  
  end
end

%% Plot polar loc ratio channel 1 vs channel 2
if two_ch
  if plot_polLoc_vs
    [type_ratio_position] = type_ratio_position_function(type_ratio);

    for strain = 1:1:nbr_strains
    
      % Plot with same or replicate color
      figure('units','normalized','outerposition',[0 0 1 1])
      axis([0 y_polLoc_st 0 y_polLoc_st])
      hold on
      ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))
      xlabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))

      type=Pil_types(strain);
      index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
      nbr_replicates = size(index_type,2);

      if rep_colour
        for rep = 1:1:nbr_replicates
          if nbr_replicates<7
            marker_rep = strcat(colour_reps(rep)," o");
          else
            marker_rep = "k o";
            disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
          end
          if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
            plot([polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,type_ratio_position(3)}],[polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1)
          end
        end
      else
        polLocs_ch1 = polar_loc_speed_motile_concat{strain, type_ratio_position(2)};
        polLocs_ch2 = polar_loc_speed_motile_concat_ch2{strain, type_ratio_position(2)};
        plot(polLocs_ch2,polLocs_ch1,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
      end

      plot([0 y_polLoc_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
      text(y_polLoc_st-0.003,no_polLoc+0.02,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again
      
      plot([no_polLoc no_polLoc],[0 y_polLoc_st],'k --','Linewidth',1)
      text(no_polLoc+0.015,0.02,"rough localization threshold FimW",'FontSize',8,'rotation',-90,'HorizontalAlignment','right') % this threshold should be checked again

      title(strcat("Polar Loc ",ch1," vs ",ch2," after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');

      graph_type = strcat('polLoc_ch1ch2',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end
      
      
      % plot with color according to speed value
      figure('units','normalized','outerposition',[0 0 1 1])
      axis([0 y_polLoc_st 0 y_polLoc_st])
      hold on
      ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))
      xlabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))

      type=Pil_types(strain);
      index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
      nbr_replicates = size(index_type,2);

      cmap = jet(256);
      speeds = polar_loc_speed_motile_concat{strain, 3};
      v = rescale(speeds, 1, 256); % Rescale values to fit colormap
      numValues = length(speeds);
      markerColors = zeros(numValues, 3);
      % Assign marker colors according to the cell speed
      for k = 1 : numValues
          row = round(v(k));
          markerColors(k, :) = cmap(row, :);
      end
      
      polLocs_ch1 = polar_loc_speed_motile_concat{strain, type_ratio_position(2)};
      polLocs_ch2 = polar_loc_speed_motile_concat_ch2{strain, type_ratio_position(2)};
      
      scatter(polLocs_ch2,polLocs_ch1,25,markerColors,'o','filled','MarkerFaceAlpha',0.75)
      
      colorTicks = round(linspace(0,max(speeds),11),3);
      colormap(cmap)
      cb = colorbar('TickLabels',colorTicks);
      cb.Label.String = "Speed (µm/s)";
      
      plot([0 y_polLoc_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
      text(y_polLoc_st-0.003,no_polLoc+0.02,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again
      
      plot([no_polLoc no_polLoc],[0 y_polLoc_st],'k --','Linewidth',1)
      text(no_polLoc+0.015,0.02,"rough localization threshold FimW",'FontSize',8,'rotation',-90,'HorizontalAlignment','right') % this threshold should be checked again

      title(strcat("Polar Loc ",ch1," vs ",ch2," after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');

      graph_type = strcat('polLoc_ch1ch2_speedcolour',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end
      
    end  
  end
end

%% Select channel 1 polar subpopulation and plot polar to cyto ratio channel 1 (typically mNG) [not really required]
% 
% if plot_polLoc_speed_ch1polar
%   [type_ratio_position] = type_ratio_position_function(type_ratio);
% 
%   for strain = 1:1:nbr_strains
%     
%     type=Pil_types(strain);
%     index_type=find([polar_loc_speed_motile_results{:,1}]==type);
%     nbr_replicates = size(index_type,2);
%     
%     index_ch1polar = cell(nbr_replicates,1);
%     index_ch1nonpolar = cell(nbr_replicates,1);
%     for rep = 1:1:nbr_replicates    
%       index_ch1polar{rep} = find([polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}]>=0.65); % find positions of tracks with polar localization of channel 1 protein
%       index_ch1nonpolar{rep} = find([polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}]<0.65); % find positions of tracks with non-polar localization of channel 1 protein
%     end
%     
%     % plot graph for polar subpopulation
%     figure('units','normalized','outerposition',[0 0 1 1])
%     axis([0 y_speed_st 0 y_polLoc_st])
%     hold on
%     ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))
%     xlabel("Speed (µm/s)")
%         
%     if rep_colour
%       for rep = 1:1:nbr_replicates
%         colour_reps = ["b","g","m","y","c","r"];
%         if nbr_replicates<7
%           marker_rep = strcat(colour_reps(rep)," o");
%         else
%           marker_rep = "k o";
%           disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
%         end
%         if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})  
%           plot([polar_loc_speed_motile_results{index_type(rep),3}{index_ch1polar{rep},5}],[polar_loc_speed_motile_results{index_type(rep),3}{index_ch1polar{rep},type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1) 
%         end
%       end
%     else
%       speeds = polar_loc_speed_motile_concat{strain, 3};
%       polLocs = polar_loc_speed_motile_concat{strain, type_ratio_position(2)};
%       plot(speeds,polLocs,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
%     end
%       
%     plot([0 y_speed_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
%     text(y_speed_st-0.001,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again
%     
%     plot([no_move no_move],[0 y_polLoc_st],'k --','Linewidth',1)
%     text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')
%     
%     title(strcat("|Ch1 polar subpop| Polar Loc vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');
%     
%     graph_type = strcat('polLoc_vs_speed_polch1',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch1);
%     if save_graphs
% %       saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
% %       saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
% %       saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
%     end
%     
%     
%     % plot graph for non-polar subpopulation
%     figure('units','normalized','outerposition',[0 0 1 1])
%     axis([0 y_speed_st 0 y_polLoc_st])
%     hold on
%     ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))
%     xlabel("Speed (µm/s)")
%         
%     if rep_colour
%       for rep = 1:1:nbr_replicates
%         colour_reps = ["b","g","m","y","c","r"];
%         if nbr_replicates<7
%           marker_rep = strcat(colour_reps(rep)," o");
%         else
%           marker_rep = "k o";
%           disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
%         end
%         if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})  
%           plot([polar_loc_speed_motile_results{index_type(rep),3}{index_ch1nonpolar{rep},5}],[polar_loc_speed_motile_results{index_type(rep),3}{index_ch1nonpolar{rep},type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1) 
%         end
%       end
%     else
%       speeds = polar_loc_speed_motile_concat{strain, 3};
%       polLocs = polar_loc_speed_motile_concat{strain, type_ratio_position(2)};
%       plot(speeds,polLocs,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
%     end
%       
%     plot([0 y_speed_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
%     text(y_speed_st-0.001,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again
%     
%     plot([no_move no_move],[0 y_polLoc_st],'k --','Linewidth',1)
%     text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')
%     
%     title(strcat("|Ch1 non-polar subpop| Polar Loc vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');
%     
%     graph_type = strcat('polLoc_vs_speed_nonpolch1',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch1);
%     if save_graphs
% %       saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
% %       saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
% %       saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
%     end
%   end  
% end

%% Select channel 1 polar subpopulation and plot polar to cyto ratio channel 2 (typically mNG)

if two_ch
  if plot_polLoc_speed_ch1polar
    [type_ratio_position] = type_ratio_position_function(type_ratio);

    for strain = 1:1:nbr_strains

      type=Pil_types(strain);
      index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
      nbr_replicates = size(index_type,2);

      index_ch1polar = cell(nbr_replicates,1);
      index_ch1nonpolar = cell(nbr_replicates,1);
      for rep = 1:1:nbr_replicates    
        index_ch1polar{rep} = find([polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}]>=0.65); % find positions of tracks with polar localization of channel 1 protein
        index_ch1nonpolar{rep} = find([polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}]<0.65); % find positions of tracks with non-polar localization of channel 1 protein
      end

      % plot graph for polar subpopulation
      figure('units','normalized','outerposition',[0 0 1 1])
      axis([0 y_speed_st 0 y_polLoc_st])
      hold on
      ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))
      xlabel("Speed (µm/s)")

      if rep_colour
        for rep = 1:1:nbr_replicates
          if nbr_replicates<7
            marker_rep = strcat(colour_reps(rep)," o");
          else
            marker_rep = "k o";
            disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
          end
          if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})  
            plot([polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1polar{rep},5}],[polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1polar{rep},type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1) 
          end
        end
      else
        speeds = polar_loc_speed_motile_concat_ch2{strain, 3};
        polLocs = polar_loc_speed_motile_concat_ch2{strain, type_ratio_position(2)};
        plot(speeds,polLocs,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
      end

      plot([0 y_speed_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
      text(y_speed_st-0.001,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again

      plot([no_move no_move],[0 y_polLoc_st],'k --','Linewidth',1)
      text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')

      title(strcat("|Ch1 polar subpop| Polar Loc vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat_ch2{strain,7})," tracks)"),'Interpreter','none');

      graph_type = strcat('polLoc_vs_speed_polch1',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch2);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end


      % plot graph for channel 1 non-polar subpopulation
      figure('units','normalized','outerposition',[0 0 1 1])
      axis([0 y_speed_st 0 y_polLoc_st])
      hold on
      ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))
      xlabel("Speed (µm/s)")

      if rep_colour
        for rep = 1:1:nbr_replicates
          if nbr_replicates<7
            marker_rep = strcat(colour_reps(rep)," o");
          else
            marker_rep = "k o";
            disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
          end
          if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})  
            plot([polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1nonpolar{rep},5}],[polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1nonpolar{rep},type_ratio_position(3)}],marker_rep,'MarkerSize',5,'Linewidth',1) 
          end
        end
      else
        speeds = polar_loc_speed_motile_concat_ch2{strain, 3};
        polLocs = polar_loc_speed_motile_concat_ch2{strain, type_ratio_position(2)};
        plot(speeds,polLocs,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
      end

      plot([0 y_speed_st],[no_polLoc no_polLoc],'k --','Linewidth',1)
      text(y_speed_st-0.001,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again

      plot([no_move no_move],[0 y_polLoc_st],'k --','Linewidth',1)
      text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')

      title(strcat("|Ch1 non-polar subpop| Polar Loc vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat_ch2{strain,7})," tracks)"),'Interpreter','none');

      graph_type = strcat('polLoc_vs_speed_nonpolch1',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch2);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end
    end  
  end
end

%% Select channel 1 polar subpopulation and plot polar to cytoplasmic ratio all tracks channel 2 (typically mScI)

if two_ch
  if plot_polLoc_vs_ch1polar
    [type_ratio_position] = type_ratio_position_function(type_ratio);
    

    figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
    axis([0 (nbr_strains*2)+1 0 y_polLoc_vio])
    hold on    
    ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch2,")"))

    x_val = 0;
    leg=[""];
    for strain = 1:1:nbr_strains
      leg=[leg,strcat(Pil_types(strain)," |p|"),strcat(Pil_types(strain)," |np|")]; 

      type=Pil_types(strain);
      index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
      nbr_replicates = size(index_type,2);

      index_ch1polar = cell(nbr_replicates,1);
      index_ch1nonpolar = cell(nbr_replicates,1);
      for rep = 1:1:nbr_replicates    
        index_ch1polar{rep} = find([polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}]>=0.65); % find positions of tracks with polar localization of channel 1 protein
        index_ch1nonpolar{rep} = find([polar_loc_speed_motile_results{index_type(rep),3}{:,type_ratio_position(3)}]<0.65); % find positions of tracks with non-polar localization of channel 1 protein
      end
      
      % plot graph for channel 1 polar subpopulation
      x_val = x_val+1;
      mean_data_plot = zeros(nbr_replicates,1);
      data_concat_reps = [];
      for rep = 1:1:nbr_replicates
          if rep_colour
            if nbr_replicates<7
              marker_rep = strcat(colour_reps(rep)," o");
            else
              marker_rep = "k o";
              disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
            end
        else
            marker_rep = "k o";
        end
        if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
          data_concat_reps = [data_concat_reps,polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1polar{rep},type_ratio_position(3)}];
          mean_data_plot(rep) = median([polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1polar{rep},type_ratio_position(3)}]);
          plot(x_val,mean_data_plot(rep),marker_rep,'MarkerSize',8,'Linewidth',1) % plots median polar loc ratio of the replicate
        end
      end
      mean_data = mean(mean_data_plot);      
      plot([x_val-0.15 x_val+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates 
      text(x_val, 0.05, num2str(size(data_concat_reps,2)), 'HorizontalAlignment','center'); % plots number of tracks
      if plot_violin
        violin(x_val, data_concat_reps,'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
      end
      
      % plot graph for channel 1 non-polar subpopulation 
      x_val = x_val+1;
      mean_data_plot = zeros(nbr_replicates,1);
      data_concat_reps = [];
      for rep = 1:1:nbr_replicates
          if rep_colour
            if nbr_replicates<7
              marker_rep = strcat(colour_reps(rep)," o");
            else
              marker_rep = "k o";
              disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
            end
        else
            marker_rep = "k o";
        end
        if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
          data_concat_reps = [data_concat_reps,polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1nonpolar{rep},type_ratio_position(3)}];
          mean_data_plot(rep) = median([polar_loc_speed_motile_results_ch2{index_type(rep),3}{index_ch1nonpolar{rep},type_ratio_position(3)}]);
          plot(x_val,mean_data_plot(rep),marker_rep,'MarkerSize',8,'Linewidth',1) % plots median polar loc ratio of the replicate
        end
      end
      mean_data = mean(mean_data_plot);      
      plot([x_val-0.15 x_val+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates 
      text(x_val, 0.05, num2str(size(data_concat_reps,2)), 'HorizontalAlignment','center'); % plots number of tracks
      if plot_violin
        violin(x_val, data_concat_reps,'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
      end
    end
    
    set(gca, 'XTickLabel',leg, 'Fontsize',15, 'Ticklabelinterpreter', 'none')
    xticks([0:1:nbr_strains*2+1])
    xtickangle(15)

    plot([0 nbr_strains*2+1],[no_polLoc no_polLoc],'k --','Linewidth',1)
    text(0.03,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8) % this threshold should be checked again
    title(strcat(tos," surface |ch1 polar vs non-polar subpopulation|"));

    graph_type = strcat('polLoc_ratio_polnonpolch1',addition,'_',type_ratio,'_',ch2);
    if save_graphs
      saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
      saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
      saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end 
  end
end

%% Plot polar asymmetry ratio all tracks channel 1 (typically mNG)

if plot_polAsym
  
  figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
  axis([0 nbr_strains+2 0 y_polAsym_vio])
  hold on
  set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
  xticks([0:1:nbr_strains+1])
  xtickangle(15)
  ylabel(strcat("Asymmetry index (",type_ratio,", ",ch1,")"))

  x_val = [];
  leg=[];
  for strain = 1:1:nbr_strains
    leg=[leg,Pil_types(strain)]; 
        
    type=Pil_types(strain);
    index_type=find([polar_loc_speed_motile_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    
    x_val = [x_val,strain];
    for rep = 1:1:nbr_replicates
        if rep_colour
            if nbr_replicates<7
              marker_rep = strcat(colour_reps(rep)," o");
            else
              marker_rep = "k o";
              disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
            end
        else
            marker_rep = "k o";
        end
        if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
        plot(x_val(strain),1-polar_loc_speed_motile_results{index_type(rep),8},marker_rep,'MarkerSize',8,'Linewidth',1.5) % plots median polar loc ratio of the replicate
        end
    end
    mean_data = mean(1-[polar_loc_speed_motile_results{index_type,8}]);      
    plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates 
    text(x_val(strain), 0.05, num2str(polar_loc_speed_motile_concat{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
    if plot_violin
      violin(x_val(strain), 1-polar_loc_speed_motile_concat{strain,8},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
    end
  end
  
  plot([0 nbr_strains+2],[no_polAsym no_polAsym],'k --','Linewidth',1)
  text(0.03,no_polAsym+0.01,"rough symmetry threshold PilB",'FontSize',8) % this threshold should be checked again
  title(strcat("Asymmetry index after ",tos," on surface"));
  
  graph_type = strcat('polAsym',addition,'_',type_ratio,'_',ch1);
  if save_graphs
    saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
    saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
    saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
  end
end

%% Plot polar asymmetry ratio all tracks channel 2 (typically mScI)

if two_ch
    if plot_polAsym

      figure('units','normalized','outerposition',[0 0 1/aspect_data 1])
      axis([0 nbr_strains+2 0 y_polAsym_vio])
      hold on
      set(gca, 'XTickLabel',["",Pil_types(1:nbr_strains)], 'Fontsize',15, 'Ticklabelinterpreter', 'none')
      xticks([0:1:nbr_strains+1])
      xtickangle(15)
      ylabel(strcat("Asymmetry index (",type_ratio,", ",ch2,")"))

      x_val = [];
      leg=[];
      for strain = 1:1:nbr_strains
        leg=[leg,Pil_types(strain)]; 

        type=Pil_types(strain);
        index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
        nbr_replicates = size(index_type,2);

        x_val = [x_val,strain];
        for rep = 1:1:nbr_replicates
            if rep_colour
                if nbr_replicates<7
                  marker_rep = strcat(colour_reps(rep)," o");
                else
                  marker_rep = "k o";
                  disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
                end
            else
                marker_rep = "k o";
            end
            if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
            plot(x_val(strain),1-polar_loc_speed_motile_results_ch2{index_type(rep),8},marker_rep,'MarkerSize',8,'Linewidth',1.5) % plots median polar loc ratio of the replicate
            end
        end
        mean_data = mean(1-[polar_loc_speed_motile_results_ch2{index_type,8}]);      
        plot([x_val(strain)-0.15 x_val(strain)+0.15],[mean_data mean_data],'k -','Linewidth',3) % plots mean polar loc ratio over all replicates 
        text(x_val(strain), 0.05, num2str(polar_loc_speed_motile_concat{strain,7}), 'HorizontalAlignment','center'); % plots number of tracks
        if plot_violin
          violin(x_val(strain), 1-polar_loc_speed_motile_concat_ch2{strain,8},'facealpha',0.42,'linewidth',0.5,'style',2,'side','right','scaling',scaling_violin_polLoc) % plots distribution of single-track values combined for all replicates
        end
      end

      plot([0 nbr_strains+2],[no_polAsym no_polAsym],'k --','Linewidth',1)
      text(0.03,no_polAsym+0.01,"rough symmetry threshold PilB",'FontSize',8) % this threshold should be checked again
      title(strcat("Asymmetry index after ",tos," on surface"));

      graph_type = strcat('polAsym',addition,'_',type_ratio,'_',ch2);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end
    end
end

%% Plot asymmetry index vs speed channel 1 (typically mNG)
if plot_polAsym_speed
  
  for strain = 1:1:nbr_strains
    
    figure('units','normalized','outerposition',[0 0 1 1])
    axis([0 y_speed_st 0 y_polAsym_vio])
    hold on
    ylabel(strcat("Asymmetry index (",type_ratio,", ",ch1,")"))
    xlabel("Speed (µm/s)")
            
    type=Pil_types(strain);
    index_type=find([polar_loc_speed_motile_results{:,1}]==type);
    nbr_replicates = size(index_type,2);
    
    if rep_colour
      for rep = 1:1:nbr_replicates
        if nbr_replicates<7
          marker_rep = strcat(colour_reps(rep)," o");
        else
          marker_rep = "k o";
          disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
        end
        if ~isempty(polar_loc_speed_motile_results{index_type(rep),3})
          plot([polar_loc_speed_motile_results{index_type(rep),3}{:,5}],1-[polar_loc_speed_motile_results{index_type(rep),3}{:,12}],marker_rep,'MarkerSize',5,'Linewidth',1) 
        end
      end
    else
      speeds = polar_loc_speed_motile_concat{strain, 3};
      polAsyms = polar_loc_speed_motile_concat{strain, 8};
      plot(speeds,polAsyms,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
    end
      
    plot([no_move no_move],[0 y_polAsym_vio],'k --','Linewidth',1)
    text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')
    
    plot([0 y_speed_st],[no_polAsym no_polAsym],'k --','Linewidth',1)
    text(y_speed_st-0.001,no_polAsym+0.01,"rough symmetry threshold PilB",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again
    
    title(strcat("Polar Asymmetry vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');
    
    graph_type = strcat('polAsym_vs_speed',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch1);
    if save_graphs
      saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
      saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
      saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
    end
  end  
end

%% Plot asymmetry index vs speed channel 2 (typically mScI)

if two_ch
    if plot_polAsym_speed

      for strain = 1:1:nbr_strains

        figure('units','normalized','outerposition',[0 0 1 1])
        axis([0 y_speed_st 0 y_polAsym_vio])
        hold on
        ylabel(strcat("Asymmetry index (",type_ratio,", ",ch2,")"))
        xlabel("Speed (µm/s)")

        type=Pil_types(strain);
        index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
        nbr_replicates = size(index_type,2);

        if rep_colour
          for rep = 1:1:nbr_replicates
            if nbr_replicates<7
              marker_rep = strcat(colour_reps(rep)," o");
            else
              marker_rep = "k o";
              disp(strcat("WARNING: Too many replicates. Can't plot replicate-specific colours for strain ",type))
            end
            if ~isempty(polar_loc_speed_motile_results_ch2{index_type(rep),3})
              plot([polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,5}],1-[polar_loc_speed_motile_results_ch2{index_type(rep),3}{:,12}],marker_rep,'MarkerSize',5,'Linewidth',1) 
            end
          end
        else
          speeds = polar_loc_speed_motile_concat_ch2{strain, 3};
          polAsyms = polar_loc_speed_motile_concat_ch2{strain, 8};
          plot(speeds,polAsyms,"k o",'MarkerSize',5,'Linewidth',1) % plots polar localization motile index vs speed per track
        end

        plot([no_move no_move],[0 y_polAsym_vio],'k --','Linewidth',1)
        text(no_move+0.003,0.025,"rough no-move threshold",'FontSize',8,'rotation',-90,'HorizontalAlignment','right')

        plot([0 y_speed_st],[no_polAsym no_polAsym],'k --','Linewidth',1)
        text(y_speed_st-0.001,no_polAsym+0.01,"rough symmetry threshold PilB",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again

        title(strcat("Polar Asymmetry vs Speed after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');

        graph_type = strcat('polAsym_vs_speed',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio,'_',ch2);
        if save_graphs
          saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
          saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
          saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
        end
      end  
    end
end

%% Plot polar loc ratio channel 1 vs channel 2
if two_ch
  if plot_polLoc_vs_polAsym
    [type_ratio_position] = type_ratio_position_function(type_ratio);

    for strain = 1:1:nbr_strains
       
      % plot with color according to speed value
      figure('units','normalized','outerposition',[0 0 1 1])
      axis([0 y_polAsym_vio 0 y_polLoc_st+0.1])
      hold on
      ylabel(strcat("Ratio pole / cytoplasm (",type_ratio,", ",ch1,")"))
      xlabel(strcat("Asymmetry index (",type_ratio,", ",ch2,")"))

      type=Pil_types(strain);
      index_type=find([polar_loc_speed_motile_results_ch2{:,1}]==type);
      nbr_replicates = size(index_type,2);

      cmap = jet(256);
      speeds = polar_loc_speed_motile_concat{strain, 3};
      v = rescale(speeds, 1, 256); % Rescale values to fit colormap
      numValues = length(speeds);
      markerColors = zeros(numValues, 3);
      % Assign marker colors according to the cell speed
      for k = 1 : numValues
          row = round(v(k));
          markerColors(k, :) = cmap(row, :);
      end
      
      polLocs_ch1 = polar_loc_speed_motile_concat{strain, type_ratio_position(2)};
      polAsym_ch2 = 1-polar_loc_speed_motile_concat_ch2{strain, 8};
      
      scatter(polAsym_ch2,polLocs_ch1,25,markerColors,'o','filled','MarkerFaceAlpha',0.75)
      
      colorTicks = round(linspace(0,max(speeds),11),3);
      colormap(cmap)
      cb = colorbar('TickLabels',colorTicks);
      cb.Label.String = "Speed (µm/s)";
      
      plot([no_polAsym no_polAsym],[0 y_polLoc_st+0.1],'k --','Linewidth',1)
      text(no_polAsym+0.005,0.01,"rough symmetry threshold PilB",'FontSize',8,'rotation',-90,'HorizontalAlignment','right') % this threshold should be checked again
      
      plot([0 y_polLoc_st+0.1],[no_polLoc no_polLoc],'k --','Linewidth',1)
      text(y_polAsym_vio-0.004,no_polLoc+0.03,"rough localization threshold FimW",'FontSize',8,'HorizontalAlignment','right') % this threshold should be checked again

      title(strcat("Polar Loc ",ch1," vs ",ch2," after ",tos," on surface (",type,", ",num2str(nbr_replicates)," reps, ",num2str(polar_loc_speed_motile_concat{strain,7})," tracks)"),'Interpreter','none');

      graph_type = strcat('polLoc_ch1_asymIndex_ch2_speedcolour',addition,'_',num2str(sscanf(type,'%i')),'_',type_ratio);
      if save_graphs
        saveas(gcf,strcat(save_dir,save_name,graph_type,'.jpg'));
        saveas(gcf,strcat(save_dir,'fig_files\',save_name,graph_type,'.fig'));
        saveas(gcf,strcat(save_dir,'svg_files\',save_name,graph_type,'.svg'));
      end
      
    end  
  end
end
