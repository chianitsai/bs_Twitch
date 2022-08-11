function removeAxis(h_axes)

axis(h_axes, 'off');
h_axes.XAxis.Visible = 'off';
h_axes.YAxis.Visible = 'off';
try
    vers = version('-release');
    if (str2double(vers(1:4)) == 2018 && strcmp(vers(5), 'b')) || str2double(vers(1:4)) > 2018
        
        h_axes.Toolbar.Visible = 'off';
        h_axes.Toolbar = [];
    end
end