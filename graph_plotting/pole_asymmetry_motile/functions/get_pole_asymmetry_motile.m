function [tot_moving_asymm,tot_non_moving_asymm] = get_symm_asymm(directory1,Pil_type, dates_B, intervals_B,limite_ratio,useMax)
%OUTPUT:
    % the output is alignment_counts which is a cell of 4 columns 
    % column 1 = day number; from 1 to size(dates,1)
    % column 2 = folder number
    % column 3 = number of tracks with average polar ratio < limite_ratio (0.69)
    % column 4 = total number of tracks


index_per_video_non_moving=[];
index_per_video_moving=[];
j=0;
for d=1:1:size(dates_B,1) % sometimes has to be 1, sometimes 2, who knows why
    date=num2str(dates_B{d}) % for Marco's version of save_distribution_asymmetry_MJK
%     date=dates_B{d}; % for Iscia's version of save_distribution_asym_sym
    interval=intervals_B{d}
    
    adresse_folder=strcat(directory1,Pil_type,'/',date,'/',interval);
%     num_folder=length(dir(adresse_folder))-2;
    [num_folder] = correct_folder_number(adresse_folder);
    
    for folder=1:1:num_folder
        
        mean_ratio_non_moving=[];
        mean_ratio_moving=[];
        j=j+1;
        Pil_nbr=folder;
        adresse_data=strcat(directory1,Pil_type,'/',date,'/',interval,'/',num2str(Pil_nbr));
        addpath(adresse_data) % for the folder
        load('variables.mat','cell_prop','cell_prop_non_moving','BactID','BactID_non_moving')
     
%% Moving cells
        nbr_bact=size(BactID,1);
        if nbr_bact==0
            tot_moving_asymm(j,3)=0;
            tot_moving_asymm(j,1)=d;
            tot_moving_asymm(j,2)=folder;
            tot_moving_asymm(j,4)=nbr_bact;
        else  
            for nbr=1:1:nbr_bact
                if useMax
                    for frame=1:1:size(cell_prop{nbr,10},1)
                        cell_prop{nbr,11}(frame,1) = min(cell_prop{nbr,10}{frame,1}) / max(cell_prop{nbr,10}{frame,1});
                    end
                    mean_ratio_moving(nbr,1)=mean(cell_prop{nbr,11});
                else   
                    mean_ratio_moving(nbr,1)=mean(cell_prop{nbr,9});
                end
            end
            tot_moving_asymm(j,3)=sum(mean_ratio_moving(:,1)<=limite_ratio);
            tot_moving_asymm(j,1)=d;
            tot_moving_asymm(j,2)=folder;
            tot_moving_asymm(j,4)=nbr_bact;
        end
%% Non moving cells
        nbr_bact=size(BactID_non_moving,1);
        for nbr=1:1:nbr_bact
            if useMax
                for frame=1:1:size(cell_prop_non_moving{nbr,10},1)
                    cell_prop_non_moving{nbr,11}(frame,1) = min(cell_prop_non_moving{nbr,10}{frame,1}) / max(cell_prop_non_moving{nbr,10}{frame,1});
                end
                mean_ratio_non_moving(nbr,1)=mean(cell_prop_non_moving{nbr,11});
            else
                mean_ratio_non_moving(nbr,1)=mean(cell_prop_non_moving{nbr,9});
            end
        end
        tot_non_moving_asymm(j,3)=sum(mean_ratio_non_moving(:,1)<limite_ratio);
        tot_non_moving_asymm(j,1)=d;
        tot_non_moving_asymm(j,2)=folder;
        tot_non_moving_asymm(j,4)=nbr_bact;
       
       rmpath(adresse_data)  
    
    end 
end
end

