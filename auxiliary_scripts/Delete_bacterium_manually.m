% To delete manually the cells that has been wrongly segmented and/or tracked
clear all
close all
%% Insert Info
dir_data='G:\Marco\bs_Twitch_data_storage\';
dir_func='C:\Users\mkuehn\git\bs_Twitch\basic_analysis\Matlab_scripts\';
Pil_type='1044 fliC- mNG_FimX pilA-';
date='20200908';
%interval='2s interval';
Pil_nbr='5s interval-60min\6';
bacteria_to_del={'70'};
moving=1; %1:YES 0:NO
 %% add path 
 addpath(strcat(dir_func,'Functions'));
 adresse_data=strcat(dir_data,Pil_type,'\',date,'\',Pil_nbr);
 addpath(adresse_data) % for the folder
 %% add variables
 load(strcat(adresse_data,'\variables.mat'))
 do_video=0; %1:YES 0:NO
 
 %% START
 %--- if movig cells-------
 if moving
     for i=1:1:length(bacteria_to_del)
         selected_bact=str2double(bacteria_to_del{i});
         nbr=find(BactID(:,1)==selected_bact);

         BactID(nbr,:)=[];
         cell_prop(nbr,:)=[];
         Data_alignment(nbr,:)=[];
         Data_intensity(nbr,:)=[];
         Data_projection(nbr,:)=[];
         Data_speed(nbr,:)=[];
     end
     nbr_bact=size(BactID,1);
     if do_video
       create_image_for_video(adresse_data,cell_prop,1);
     end
%--- if non-movig cells-------
 elseif ~moving
     for i=1:1:length(bacteria_to_del)
     selected_bact=str2double(bacteria_to_del{i});
     nbr=find(BactID_non_moving(:,1)==selected_bact);
     
     BactID_non_moving(nbr,:)=[];
     cell_prop_non_moving(nbr,:)=[];
     Data_intensity_non_moving(nbr,:)=[];
     Data_speed_non_moving(nbr,:)=[];
     end
     if do_video
        create_image_for_video(adresse_data,cell_prop_non_moving,0);
     end
 end

 %% save the data
 clear bacteria_to_del  
 save(strcat(adresse_data,'\variables.mat'))
 %% remove path
 rmpath(adresse_data);
