setlocal enabledelayedexpansion
set "WHITELIST=uup.iso bin slim_iso.cmd slim_config.ini"
set "SRC=uup.iso"
set "OUT=output.iso"
set "UNZIP=iso_tmp"
set "MOUNT=wim_tmp"

for /d %%d in (*) do set k=0 & for %%w in (%WHITELIST%) do if /i "%%d"=="%%w" set k=1 & if !k!==0 rd/s/q "%%d"
for %%f in (*.*) do set k=0 & for %%w in (%WHITELIST%) do if /i "%%f"=="%%w" set k=1 & if !k!==0 del/f/q "%%f"

md "%UNZIP%" "%MOUNT%" 2>nul
bin\7z.exe x "%SRC%" -o"%UNZIP%" -y
del "%SRC%"

if exist "%UNZIP%\sources\install.wim" (
    set "WIM=%UNZIP%\sources\install.wim"
) else (
    set "WIM=%UNZIP%\sources\install.esd"
)

for /f %%n in ('dism /get-wiminfo /wimfile:"%WIM%" ^| find /i "Index" ^| find /c /v ""') do set "num=%%n"

for /l %%i in (1,1,%num%) do (
rd/s/q "%MOUNT%" 2>nul & md "%MOUNT%"
dism /mount-image /imagefile:"%WIM%" /index:%%i /mountDir:"%MOUNT%"

set "SEC="
for /f "usebackq delims=" %%l in ("slim_config.ini") do (
set "t=%%l"
if not "!t!"=="" if not "!t:~0,1!"==";" (
if "!t!"=="[FEATURES]" (set "SEC=F")
if "!t!"=="[CAPABILITIES]" (set "SEC=C")
if "!SEC!"=="F" for /f "tokens=1*" %%x in ("%%l") do (
dism /image:"%MOUNT%" /disable-feature /featurename:"%%x" %%y
)
if "!SEC!"=="C" (
dism /image:"%MOUNT%" /remove-capability /capabilityname:"%%l"
)
)
)

dism /image:"%MOUNT%" /cleanup-image /startcomponentcleanup /resetbase
dism /unmount-image /mountDir:"%MOUNT%" /commit
)

bin\cdimage.exe -b"%UNZIP%\boot\etfsboot.com" -u2 -h -m -lWIN_SLIM "%UNZIP%" "%OUT%"
rd/s/q "%UNZIP%" "%MOUNT%"
:EOF