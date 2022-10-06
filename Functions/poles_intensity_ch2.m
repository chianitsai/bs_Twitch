function [int_pole_mean,ratio_poles, int_max, int_poles_total] = poles_intensity_ch2(adresse,poles,Bact_info,t,delta_x)
t=Bact_info{t,1};

imageData_fluo = imread(strcat(adresse,'\C2-data.tif'),t);

[xDim,yDim]=size(imageData_fluo);
int_pole_mean=zeros(1,size(poles,1));
int_max=zeros(1,size(poles,1));
 for i=1:1:size(poles,1)
   masque_cercle=uint16(mask(poles(i,1),poles(i,2),poles(i,3),xDim,yDim));
   nbr_pixel=sum(sum(masque_cercle));
   img=masque_cercle.*imageData_fluo;
   %radius_um=poles(i,3)*delta_x; % to transform pixel in micro meters
   %cercle_area=pi*(radius_um^2);
   int_pole_mean(i)=sum(sum(img))/nbr_pixel;%cercle_area;
   int_max(i)=max(max(img));
   int_total(i) = sum(sum(img));
 end
 int_poles_total = sum(int_total);
 ratio_poles=min(int_pole_mean(1:2))/max(int_pole_mean(1:2));
end

