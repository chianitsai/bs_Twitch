clear all
close all
load('Cleaned_Asymm_Symm_distribution.mat')

%% Moving cells

counter = 0;

for i = 1:1:size(moving_distribution,1)
        
    days = unique(moving_distribution{i, 2}(:,1));
    
    for j = 1:1:size(days,1)
    indices = find((moving_distribution{i, 2}(:,1))== days(j));
    counter = counter+1;
    SampleSize(counter,1) = sum(moving_distribution{i, 2}(indices,4));
    end
    
   end

%% Non-Moving cells

counter = 0;

for i = 1:1:size(non_moving_distribution,1)
        
    days = unique(non_moving_distribution{i, 2}(:,1));
    
    for j = 1:1:size(days,1)
    indices = find((non_moving_distribution{i, 2}(:,1))== days(j));
    counter = counter+1;
    SampleSize(counter,2) = sum(non_moving_distribution{i, 2}(indices,4));
    end
    
   end