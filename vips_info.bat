@echo off
set VIPSPATH=%LOCALAPPDATA%\vips\bin\vips.exe
set OUTPUT=%TEMP%\vips_info.txt

echo === VIPS Installation Check === > "%OUTPUT%"
echo. >> "%OUTPUT%"

if exist "%VIPSPATH%" (
    echo VIPS trouve: %VIPSPATH% >> "%OUTPUT%"
    echo. >> "%OUTPUT%"

    echo === Version VIPS === >> "%OUTPUT%"
    "%VIPSPATH%" --version >> "%OUTPUT%" 2>&1
    echo. >> "%OUTPUT%"

    echo === Help commande copy === >> "%OUTPUT%"
    "%VIPSPATH%" copy >> "%OUTPUT%" 2>&1
    echo. >> "%OUTPUT%"

) else (
    echo VIPS non trouve! >> "%OUTPUT%"
)

echo Resultats sauvegardes dans: %OUTPUT%
type "%OUTPUT%"
