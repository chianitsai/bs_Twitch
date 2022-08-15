function [int_cyto_total,int_cyto_mean] = cyto_intensity(adresse,contour_t,poles,Bact_info,t)
t=Bact_info{t,1};

imageData_fluo = imread(strcat(adresse,'\C1-data.tif'),t);

[xDim,yDim]=size(imageData_fluo);
mask_pole_1=mask(poles(1,1),poles(1,2),poles(1,3),xDim,yDim);
mask_pole_2=mask(poles(2,1),poles(2,2),poles(2,3),xDim,yDim);
mask_poles_inv = uint16(~or(mask_pole_1,mask_pole_2));

mask_cell = uint16(roipoly(imageData_fluo,contour_t(:,2),contour_t(:,1))); % makes a mask with the dimensons of imageData_fluo that contains all pixels in inside the outline defined by contour_t (strangely they have the format y-coordinates, x-coordinates)
mask_cyto = mask_cell.*mask_poles_inv;

nbr_pixel=sum(sum(mask_cyto));
imageData_fluo_masked=mask_cyto.*imageData_fluo;

int_cyto_total = sum(sum(imageData_fluo_masked));
int_cyto_mean = sum(sum(imageData_fluo_masked))/nbr_pixel;
end

