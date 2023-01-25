% !This code removes all the redundant image sequence copies created by the
% BacStalk analysis pipeline. This includes the split and duplicated C0 and
% C1 channels, but also the Movie folders with the track visualizations!
close all
clear all

%% To Modify:
directory = 'G:\Marco\bs_locprof_data_storage\source_data_figure_8\oscillations_data\'; 

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
                    
                    %% Step 5: Delete files
                    
                    num_files = length(content_movie)-2;
                    
                    files = {content_movie(3:end).name};
                                       
                    for f = 1:1:num_files
                    
                        file = files{f};
                        
                        if contains(file,'C0-data') & contains (file,'.tif')
                        
                            path_file = strcat(subdir_movie,'\',file);
                            delete(path_file);
                            
                            PilTypes_cleaned(t) = 1;
                                               
                        end
                        
                        if contains(file,'C1-data') & contains (file,'.tif')
                        
                            path_file = strcat(subdir_movie,'\',file);
                            delete(path_file);
                            
                            PilTypes_cleaned(t) = 1;
                                               
                        end
                        
                        if contains(file,'Movie')
                        
                            path_folder = strcat(subdir_movie,'\',file);
                            rmdir(path_folder,'s');
                            
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