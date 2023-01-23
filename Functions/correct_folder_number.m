function [num_folder] = correct_folder_number(adresse_data)

    dinfo = dir(adresse_data);
    dinfo(ismember({dinfo.name}, {'.', '..'})) = [];
    folder_names = char({dinfo([dinfo.isdir]).name});
    num_folder = length(folder_names);
end