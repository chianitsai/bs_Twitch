function [save_dir_name, save_name] = save_displacement_maps(save_dir)

%% Saves the file real_displacement_results.mat
    % wich are the displacements corrected for the twitching direction of
    % the cell relative to the initial leading pole (which is defined as
    % the leading pole at the first significant speed (i.e. above speed limit
    % from Analysis_phase_contrast.m))
    
    % cell with 3 columns
        % 1: Pil_type
        % 2: date
        % 3: cell with 4 columns of displacement and speed data
            % 1: bact_id (which really is the id of the track; one cell can have multiple track ids!
            % 2: length of track (in timepoints)
            % 3: direction-corrected displacement in µm (using non-speed-filtered displacement and rounded alignment factor of unitary speed and unitary cell direction vector)
            % 4: filtered speed in µm/s            

%% To modify:

dir_data_input='/Volumes/Gani_sv_WS/git/bs_Twitch/graph_plotting/';
dir_data='/Volumes/Gani_sv_WS/bs_Twitch_data_storage/'; %get data analysed from ONLY phase contrast images.
dir_func='/Volumes/Gani_sv_WS/git/bs_Twitch/';
save_dir = strcat(save_dir,'mat_files/');
addpath(strcat(dir_func,'Functions'));

% Select folders from csv file (Format column 1, 2, 3 must be Pil_types, dates, intervals, respectively)
[num,txt,~]=xlsread(strcat(dir_data_input,'Data_Input_Graph_Plotting.xlsx')); % must be located in 'dir_data_input'
dates = num(:,1)'; % read as a column vector
dates_unique = unique(dates);
Pil_types = txt(:,1); % read as a cell with one column
intervals = txt(:,3); % read as a cell with one column

%% Loop over all Pil_types + dates + intervals
m = 0;
Pil_nums = [];
for type=1:1:size(Pil_types,1)
    m = m+1;

    Pil_type=convertCharsToStrings(Pil_types{type})
    Pil_nums = [Pil_nums, sscanf(Pil_type,'%i')];
    date=convertCharsToStrings(num2str(dates(type)))
    interval=convertCharsToStrings(intervals{type})
    
    adresse_data=strcat(dir_data,Pil_type,'/',date,'/',interval,'/');
%     num_folder=length(dir(adresse_data))-2;
    [num_folder] = correct_folder_number(adresse_data);
    
  %% Loop over all folders

  disp_all_comb = [];
  for folder=1:1:num_folder
    %% Load variables and add path
    adresse=strcat(adresse_data,num2str(folder))
    addpath(adresse)
    load(strcat(adresse,'/variables.mat'),'cell_prop','BactID','Data_speed')
    load(strcat(adresse,'/parameters.mat'),'delta_x');
    
    nbr_bact=size(BactID,1);

    %% loop over all cells (rather all tracks)
    
    disp_all = [];
    for nbr=1:1:nbr_bact       
        %% Get displacement
        CM=cell_prop{nbr,3};
        tracked_time=BactID(nbr,2);
        
        disp = {[],[],0};        
        for t = 2:1:tracked_time
            disp{t,1} = [CM(t,1)-CM(t-1,1) CM(t,2)-CM(t-1,2)] * delta_x; % displacement vector in µm
            disp{t,3} = norm(disp{t,1}); % norm of discplacement vector
            if disp{t,3}>0
                disp{t,2} = disp{t,1} / disp{t,3}; % unitary displacement vector
            elseif disp{t,3}==0
                disp{t,2} = disp{t,1} / 1; % unitary displacement vector
            end
        end

        %% Get cell movement direction relative to initial leading pole
        
        % 1. label poles
        poles=[];
        [poleA,poleB]=label_the_poles(cell_prop{nbr,5},CM); % labels the pole so that pole A and B are always the same one, respectively
        % combine poles A and B coordinates + initial label into poles
        poles(:,1:2)=poleA(:,1:2);  poles(:,5)=poleA(:,3);
        poles(:,3:4)=poleB(:,1:2);  poles(:,6)=poleB(:,3);
        
        % 2. get speed vector
        speed_filt = cell2mat(Data_speed{nbr,3}); % speed vector which is filtered by speed_limit
        speed_unfilt = cell2mat(Data_speed{nbr,6});
        
        % 3. define initial leading pole       
        tmp=1;
        scalar_product=0;
        while scalar_product==0  %% this is to define which pole is the initial leading pole
            vector_CM_poleA=poles(tmp,1:2)-CM(tmp,1:2);
            scalar_product=dot(speed_filt(tmp,:),vector_CM_poleA);
            tmp=tmp+1;
        end
        
        % 4. get indices of leading pole for poles array
        if scalar_product>0 % if scalar product>0 I know the pole poles(:,1:2) (poleA) is the initial leading 
            indice=[1,2];
        elseif scalar_product<0 % otherwise the other pole (poleB) is leading pole
            indice=[3,4];
        end
        
        % 5. get projection between the filtered speed vector and (unfiltered) displacement vector and the cell direction vector (CM-initial leading)
        v_filt_dot_celldir=[1:tracked_time-1]'; % just preallocates the size of v_dot_x_filt
        disp_dot_celldir=[1:tracked_time-1]'; % just preallocates the size of v_dot_x_unfilt
        
        mov = {0,0,0,0};
        for t=2:1:tracked_time            
            celldir = (poles(t,indice)-CM(t,1:2))/norm(poles(t,indice)-CM(t,1:2)); % unitary vector CM to initial leading pole for each time step            
            v_filt_dot_celldir(t)=dot(speed_filt(t,:)/norm(speed_filt(t,:)),(celldir)); % projection between the speed vector and cell direction vector (CM-initial leading)   
            disp_dot_celldir(t) = dot(disp{t,2},celldir); % projection between the displacement vector and cell direction vector (CM-initial leading)            
        
            % combine and clean up v_filt_dot_celldir and disp_dot_celldir into mov + add rounded movement values, i.e. just 1 or -1
            if isnan(v_filt_dot_celldir(t))==0
                mov{t,3} = v_filt_dot_celldir(t,1);
            elseif isnan(v_filt_dot_celldir(t))==1
                mov{t,3} = 0;
            end
            mov{t,4} = round(mov{t,3});
            
            mov{t,1} = disp_dot_celldir(t,1);
            mov{t,2} = round(mov{t,1});
        end
        
        %% Correct cell displacement by movement direction
        
%         disp_corr_rel_unfil = [disp{:,3}]'.*[mov{:,1}]';
%         disp_corr_abs_unfil = [disp{:,3}]'.*[mov{:,2}]';
%         
%         disp_corr_rel_fil = [disp{:,3}]'.*[mov{:,3}]';
%         disp_corr_abs_fil = [disp{:,3}]'.*[mov{:,4}]';
        
        % combine corrected displacements into 
        
%         disp_corr = cat(2,disp_corr_rel_unfil,disp_corr_abs_unfil,disp_corr_rel_fil,disp_corr_abs_fil);
        
        %% Combine displacement, movement direction and corrected displacement into disp_all
        
        disp_all{nbr,1} = cell_prop{nbr,1};
        disp_all{nbr,2} = cell_prop{nbr,2};
        disp_all{nbr,3} = [disp{:,3}]'.*[mov{:,2}]';
        disp_all{nbr,4} = Data_speed{nbr,4};
%         disp_all{nbr,3} = disp_corr;
%         disp_all{nbr,3} = disp;
%         disp_all{nbr,4} = mov;
%         disp_all{nbr,5} = disp_corr;
            
    end
    
    disp_all_comb = [disp_all_comb;disp_all]; % combines the data of all folders
    
%     real_displacement_results{m,1} = Pil_type;
%     real_displacement_results{m,2} = date;
%     real_displacement_results{m,3} = strcat("folder ",num2str(folder));
%     real_displacement_results{m,4} = disp_all;    
    
  end
  
    real_displacement_results{m,1} = Pil_type;
    real_displacement_results{m,2} = date;
    real_displacement_results{m,3} = disp_all_comb;    

  rmpath(adresse)
end

Pil_nums_unique = unique(Pil_nums);
if length(dates_unique)>10
    dates_unique = 'too_many_dates';
end
save_name = strcat(regexprep(num2str(dates_unique),'  ','_'),'_Strains_', regexprep(num2str(Pil_nums_unique),'  ','_'), '_displacement_maps_speed');
save_dir_name = strcat(save_dir,save_name);

save(save_dir_name,'real_displacement_results');
end
