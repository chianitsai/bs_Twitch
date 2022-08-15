function [speed_filter] = check_speed(speedlimit)
    if speedlimit==0
        speed_filter = 0;
    else
        speed_filter = 1;
    end      
end