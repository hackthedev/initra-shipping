@echo off
setlocal

echo Building Initra...
dotnet publish ModLoader -c Release -r win-x64 --self-contained true ^
 /p:PublishSingleFile=true ^
 /p:IncludeNativeLibrariesForSelfExtract=true

set "PUBLISH_PATH=%cd%\ModLoader\bin\Release\net8.0-windows\win-x64\publish"

if not exist "%PUBLISH_PATH%\Initra.exe" (
    echo Build failed or Initra.exe not found!
    pause
    exit /b 1
)

echo Creating Initra_Windows.zip...
powershell -Command "Compress-Archive -Path '%PUBLISH_PATH%\Initra.exe','%PUBLISH_PATH%\web' -DestinationPath '%PUBLISH_PATH%\Initra_Windows.zip' -Force"

echo Done!
echo Output: %PUBLISH_PATH%\Initra_Windows.zip
pause
endlocal
