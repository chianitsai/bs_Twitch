function [type_ratio_position] = type_ratio_position_function(type_ratio)

type_ratio_position = zeros(2,1);

if type_ratio == "mean"
    type_ratio_position(1) = 5;
    type_ratio_position(2) = 4;
    type_ratio_position(3) = 7;
end
if type_ratio == "max"
    type_ratio_position(1) = 6;
    type_ratio_position(2) = 5;
    type_ratio_position(3) = 9;
end
if type_ratio == "total"
    type_ratio_position(1)  = 7;
    type_ratio_position(2) = 6;
    type_ratio_position(3)  = 11;
end

end