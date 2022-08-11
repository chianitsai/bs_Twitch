% !This code should only be run after BacStalk in done and will not need to
% be redone anymore!!
% deletes all single image files that were needed for BacStalk. C0 and C1
% combined images are not deleted.

close all
clear all

%% To Modify:
directory = 'G:\Marco\bs_Twitch_data_storage\'; % 'H:\Iscia_WS\PersatLAb-master\'; % Main directory with all Pil_type folders and all
% Pil_types = {'1046 fliC- mNG_FimX PilH_D52E','1075 fliC- mNG_FimX PilH_D52A','1143 fliC- pilK-','1144 fliC- chpB-','1171 fliC- cpdA- pilG_D58E','1178 fliC- PilA_T8V','1211 fliC- cpdA- pilG_D58A','1245 fliC- mNG_FimX pilK-','1246 fliC- mNG_FimX chpB-','1255 fliC- pilK- + pJN105_mNG_PilK','1277 fliC- pilK- chpB-','1278 fliC- pilG- pilH- cpdA-','177 fliC-','232 fliC- pilH-','337 fliC- cpdA-','459 fliC- cpdA- pilG-','463 fliC- mNG_FimX'}; % name of the folder within directory

cd(directory)
content_dir = struct2cell(dir);
clean_content_dir = content_dir(1,:);
length_dir = length(clean_content_dir);
todel = zeros(1,length_dir);
for i = 1:length_dir
    todel(i) = isempty(str2num(clean_content_dir{i}(1)));
end
clean_content_dir(find(todel)) = [];

%% Simple way to get folder names

% open Windows powershell
% set directory: Set-Location H:\Iscia_WS\PersatLAb-master\
% get file list: dir
% copy file list to editor and automatically replace so that the format fits for Pil_types

%% Step 1: Go into Pil_type folder

% num_Pil_types = length(Pil_types);
num_Pil_types = length(clean_content_dir);

PilTypes_checked = 0;
PilTypes_cleaned = zeros(1,size(clean_content_dir,2));

 for t = 1:1:num_Pil_types
     
     % Pil_type = Pil_types{t};
     Pil_type = clean_content_dir{t};
     
     subdir_Pil_type = strcat(directory,Pil_type);
     addpath(subdir_Pil_type);
     
     content_Pil_type = dir(subdir_Pil_type);
     
     %% Step 2: Go into date folder
     
     num_dates = length(content_Pil_type)-2;
     
     dates = {content_Pil_type(3:end).name};
     
     for d = 1:1:num_dates
         
         date = dates{d};
         
         subdir_date = strcat(subdir_Pil_type,'\',date);
         addpath(subdir_date);
         
         content_date = dir(subdir_date);
         
         %% Step 3: Go into interval folder
         
         num_intervals = length(content_date)-2;
         
         intervals = {content_date(3:end).name};
         
         for i = 1:1:num_intervals
             
             interval = intervals{i};
             
             if ~contains(interval,'nyd')
                 
                subdir_interval = strcat(subdir_date,'\',interval)
                addpath(subdir_interval);
         
                content_interval = dir(subdir_interval);
                
                %% Step 4: Go into movie folders
                
                num_movies = length(content_interval)-2;
                
                movies = {content_interval(3:end).name};
                
                for m = 1:1:num_movies
                   
                    movie = movies{m};
                    
                    subdir_movie = strcat(subdir_interval,'\',movie);
                    addpath(subdir_movie);
                    
                    content_movie = dir(subdir_movie);
                    
                    %% Step 5: Delete files that match "data_t"
                    
                    num_files = length(content_movie)-2;
                    
                    files = {content_movie(3:end).name};
                                       
                    for f = 1:1:num_files
                    
                        file = files{f};
                        
                        if contains(file,'data_t') & contains (file,'.tif')
                        
                            path_file = strcat(subdir_movie,'\',file);
                            delete(path_file);
                            
                            PilTypes_cleaned(t) = 1;
                                               
                        end
                    end
                                        
                end
                                           
             end
         end
            
     end
     PilTypes_checked = PilTypes_checked+1;
 end
 
disp(strcat(num2str(sum(PilTypes_cleaned)), " folders cleaned out of ",num2str(PilTypes_checked), " checked folders"));