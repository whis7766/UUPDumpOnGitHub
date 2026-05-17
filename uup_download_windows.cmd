@echo off

cd /d "%~dp0"
if NOT "%cd%"=="%cd: =%" (
    echo Current directory contains spaces in its path.
    echo Please move or rename the directory to one not containing spaces.
    echo.
    pause
    goto :EOF
)

if "[%1]" == "[49127c4b-02dc-482e-ac4f-ec4d659b7547]" goto :START_PROCESS
REG QUERY HKU\S-1-5-19\Environment >NUL 2>&1 && goto :START_PROCESS

set command="""%~f0""" 49127c4b-02dc-482e-ac4f-ec4d659b7547
SETLOCAL ENABLEDELAYEDEXPANSION
set "command=!command:'=''!"

powershell -NoProfile Start-Process -FilePath '%COMSPEC%' ^
-ArgumentList '/c """!command!"""' -Verb RunAs 2>NUL

IF %ERRORLEVEL% GTR 0 (
    echo =====================================================
    echo This script needs to be executed as an administrator.
    echo =====================================================
    echo.
    pause
)

SETLOCAL DISABLEDELAYEDEXPANSION
goto :EOF

:START_PROCESS
set "aria2=files\aria2c.exe"
set "aria2Script=files\aria2_script_meta4.txt"
set "aria2Script_dy=files\aria2_script_dy.txt"
set "destDir=UUPs"

powershell -NoProfile -ExecutionPolicy Unrestricted .\files\get_aria2.ps1 || (pause & exit /b 1)

if NOT EXIST ConvertConfig.ini goto :NO_FILE_ERROR
if NOT EXIST CustomAppsList.txt goto :NO_FILE_ERROR

:DOWNLOAD_APPS
echo Retrieving aria2 script for Microsoft Store Apps...
"%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="aria2_download.log" -o"%aria2Script_dy%" --allow-overwrite=true --auto-file-renaming=false "https://uupdump.net/get.php?id=c780bdf0-6cc5-467f-9974-7d5bb2d7d69b&pack=zh-cn&edition=serverdatacenter&aria2=2"
if %ERRORLEVEL% GTR 0 call :DOWNLOAD_ERROR & exit /b 1
echo.

powershell -NoProfile -ExecutionPolicy Unrestricted "[IO.File]::WriteAllText('%aria2Script%', (([regex]::Replace((gc '%aria2Script%' -Raw), '(?s)\{dy\}(\r?\n\s*out=.*?\r?\n\s*checksum=sha-1=([a-f0-9]+).*?)(?=\r?\n\{dy\}|\Z)', {param($m);if([regex]::Match((gc '%aria2Script_dy%' -Raw), '(?m)^http\S+(?=\r?\n.*?\r?\n\s*checksum=sha-1='+$m.Groups[2].Value+')').Success){[regex]::Match((gc '%aria2Script_dy%' -Raw), '(?m)^http\S+(?=\r?\n.*?\r?\n\s*checksum=sha-1='+$m.Groups[2].Value+')').Value+$m.Groups[1]}else{$m.Value}})).Trim() -replace '^\p{Z}+','' -replace '\r?\n\p{Z}+(\r?\n)','$1'), (New-Object System.Text.UTF8Encoding $false));gc '%aria2Script%'"

echo Downloading the UUP set...
"%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="aria2_download.log" -x16 -s16 -j5 -c -R -d"%destDir%" -i"%aria2Script%"
if %ERRORLEVEL% GTR 0 goto :DOWNLOAD_UUPS & exit /b 1

if EXIST convert-UUP.cmd goto :START_CONVERT
pause
goto :EOF

:START_CONVERT
call convert-UUP.cmd
goto :EOF

:NO_FILE_ERROR
echo We couldn't find one of needed files for this script.
pause
goto :EOF

:DOWNLOAD_CONVERTER_ERROR
echo.
echo An error has occurred while downloading the UUP converter.
pause
goto :EOF

:DOWNLOAD_ERROR
echo.
echo We have encountered an error while downloading files.
pause
goto :EOF

:EOF
