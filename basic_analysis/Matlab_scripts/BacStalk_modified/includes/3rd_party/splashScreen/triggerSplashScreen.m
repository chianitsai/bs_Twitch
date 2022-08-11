function goOn = triggerSplashScreen(instance, data)
try
    % Open splash screen
    s = getappdata(0,'aeSplashHandle');
    
    goOn = 1;
    
    create_s = 0;
    try
        if isempty(s)
            create_s = 1;
        end
    end
    
    if (create_s && instance == 0) || instance == 1
        if isdeployed
            version = load('bacstalk_version.mat');
        else
            version = load(fullfile(data.guiPath, 'includes', 'bacstalk_version.mat'));
        end
        version = version.version;
        
        s = SplashScreen('BacStalk','loadingScreen.png',...
            'ProgressBar', 'on', ...
            'ProgressPosition', 5, ...
            'ProgressRatio', 0.0 );
        s.addText( 20, 375, sprintf('Version %s, loading, please wait...', version), 'FontSize', 18, 'Color', 'white' )
        
        setappdata(0,'aeSplashHandle',s) % Point to splashScreen handle in order to delete it when GUI opens
    end
catch
    fprintf('Spash screen cannot be displayed.\n');
end
