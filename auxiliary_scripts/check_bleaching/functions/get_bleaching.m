function [bleach]=get_bleaching(adresse)
%OUTPUT:
    %bleach is a vector containing the total intensity at every time step
    
    
time=size(imfinfo(strcat(adresse,'\C1-data.tif')),1);

for t=1:1:time
    this_image= imread(strcat(adresse,'\C1-data.tif'),t);
    bleach(t)=sum(sum(this_image));
end 
end