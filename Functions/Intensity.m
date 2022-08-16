function [Data_intensity,cell_prop] = Intensity(adresse,BactID,time,data_brut,delta_x)
%% variables
nbr_bact=size(BactID,1);
Data_intensity=cell(nbr_bact,7);
cell_prop=cell(nbr_bact,13);

%% loop on every cell
for nbr=1:1:nbr_bact
    Bact_info=Bacteria_information(time,nbr,data_brut,BactID);
    tracked_frames=BactID(nbr,2);
    % variables
    int=cell(tracked_frames,1);
    int_norm=zeros(tracked_frames,1);
    int_unitaire=cell(tracked_frames,1);
    CM1=zeros(tracked_frames,2);
    orientation=zeros(tracked_frames,1);
    poles=cell(tracked_frames,1);
    int_pole_mean=cell(tracked_frames,3);
    contour=cell(tracked_frames,1);
    ratio_poles=zeros(tracked_frames,1);
    int_poles_max=cell(tracked_frames,3);
    int_cyto_total = zeros(tracked_frames,1);
    int_cyto_mean = zeros(tracked_frames,1);
    int_poles_total = zeros(tracked_frames,1);
    %% loop on all the times the cell is segmented   
    for t=1:1:tracked_frames
        poles{t}=poles_coordinate(Bact_info,t);
        [int_pole_mean{t,1},ratio_poles(t),int_poles_max{t,1},int_poles_total(t)]=poles_intensity(adresse,poles{t},Bact_info,t,delta_x);
        int_pole_mean{t,2} = mean(int_pole_mean{t,1});
        int_pole_mean{t,3} = max(int_pole_mean{t,1});
        int_poles_max{t,2} = mean(int_poles_max{t,1});
        int_poles_max{t,3} = max(int_poles_max{t,1});
        int{t}=gradient_intensity(int_pole_mean{t},poles{t});
        int_norm(t)=norm(int{t});
        if int_norm(t)~=0
        int_unitaire{t}=int{t}/int_norm(t);
        else
        int_unitaire{t}=[0,0];
        end

        CM1(t,:)=Bact_info{t,2}.Centroid;
        orientation(t)=Bact_info{t,2}.Orientation;
        contour{t,1}=Bact_info{t,2}.CellOutlineCoordinates;
        
        % add whole-cell intensity !needs to do what the poles_intensity function is doing but with the cell contour instead of the pole circles!
        contour_t=contour{t,1};
        [int_cyto_total(t),int_cyto_mean(t)]=cyto_intensity(adresse,contour_t,poles{t},Bact_info,t);
    end
     
    Data_intensity{nbr,1}=BactID(nbr,1);
    Data_intensity{nbr,2}=tracked_frames;
    Data_intensity{nbr,3}=int;
    Data_intensity{nbr,4}=int_norm;
    Data_intensity{nbr,5}=int_unitaire;

    cell_prop{nbr,1}=BactID(nbr,1);
    cell_prop{nbr,2}=tracked_frames;
    cell_prop{nbr,3}=CM1;
    cell_prop{nbr,4}=orientation;
    cell_prop{nbr,5}=poles;
    cell_prop{nbr,6}=int_pole_mean;
    cell_prop{nbr,7}=cell2mat(Bact_info(:,1));
    cell_prop{nbr,8}=contour;
    cell_prop{nbr,9}=ratio_poles;
    cell_prop{nbr,10}=int_poles_max;
    cell_prop{nbr,11}=int_poles_total;
    cell_prop{nbr,12}=int_cyto_mean;
    cell_prop{nbr,13}=int_cyto_total;
     
end
end

