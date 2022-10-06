function [int_cell_total,int_cell_mean] = cell_intensity(adresse,contour_t,Bact_info,t)
t=Bact_info{t,1};

imageData_fluo = imread(strcat(adresse,'\C1-data.tif'),t);

mask_cell = uint16(roipoly(imageData_fluo,contour_t(:,2),contour_t(:,1))); % makes a mask with the dimensons of imageData_fluo that contains all pixels in inside the outline defined by contour_t (strangely they have the format y-coordinates, x-coordinates)

nbr_pixel=sum(sum(mask_cell));
imageData_fluo_masked=mask_cell.*imageData_fluo;

int_cell_total = sum(sum(imageData_fluo_masked));
int_cell_mean = sum(sum(imageData_fluo_masked))/nbr_pixel;
end

