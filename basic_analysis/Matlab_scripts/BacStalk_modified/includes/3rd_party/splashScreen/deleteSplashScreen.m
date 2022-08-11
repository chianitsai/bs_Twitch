function deleteSplashScreen(splashScreenHandle)

if ~isempty(splashScreenHandle) && isvalid(splashScreenHandle)
    try delete(splashScreenHandle), end
end
