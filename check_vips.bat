@echo off
chcp 65001 >nul
echo.
echo === VIPS Installation Check ===
echo.

set VIPSPATH=%LOCALAPPDATA%\vips\bin\vips.exe

if exist "%VIPSPATH%" (
    echo VIPS trouve: %VIPSPATH%
    echo.

    echo === Version VIPS ===
    "%VIPSPATH%" --version
    echo.

    echo === Test commande 'copy' ===
    "%VIPSPATH%" copy 2>&1 | findstr /i "sequential access"
    echo.

    echo === Operations disponibles ===
    "%VIPSPATH%" -l | findstr /i "copy tiffload"

) else (
    echo VIPS non trouve a: %VIPSPATH%
)

echo.
