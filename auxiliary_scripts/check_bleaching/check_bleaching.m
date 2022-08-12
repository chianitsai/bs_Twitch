%graph_bleaching
clear all
close all

dir_data='G:\Marco\bs_Twitch_data_storage\';
dir_func='C:\Users\mkuehn\git\bs_Twitch\';

%% To modify:
Pil_type='1638 mNG_FimW pch-'; % name of the folder
dates={'20220726','20220728','20220729'}; 
intervals={'5s interval-2h37','5s interval-2h37','5s interval-2h37'}; % number of intervals items has to match the number of dates items
intervals_same = 1; % if the interval folder name is identical for all dates, use 1, it will use only the first item of the intervals cell
%% figure
x_max = [];
bleach_max = [];
%%
for d=1:1:size(dates,2)
    figure('units','normalized','outerposition',[1/4 1/4 1/2 1/2])
    date=dates{d};
    if intervals_same
        interval=intervals{1};
    else
        interval=intervals{d};
    end
    leg = [];
    %% Load variables and add path
    addpath('functions'); 
    adresse_data=strcat(dir_data,Pil_type,'\',date,'\',interval);
    addpath(adresse_data)

    folders=dir(adresse_data);
    num_folders=length(folders)-2;
    
    for folder=1:1:num_folders
        adresse=strcat(adresse_data,'\',folders(folder+2).name);
        addpath(adresse) % for the folder
        adresse
        leg = [leg,strcat("Folder: ",num2str(folder))];
        %% calculate bleaching
        bleach=get_bleaching(adresse);
        x_max = [x_max,size(bleach,2)];
        bleach_max = [bleach_max,max(bleach)];
        %% Plot
        hold on
        plot(bleach,'-')
        grid on
        xlabel('Frame number');
        ylabel('Total fluorescence intensity');

    end
    axis([0 max(x_max)+1 0 max(bleach_max)*1.1])
    title(strcat(Pil_type," - ",num2str(date), " - ",interval),'Fontsize',10,'Interpreter','none');
    legend(leg,'Fontsize',10,'Interpreter','none', 'Location', 'bestoutside');
end