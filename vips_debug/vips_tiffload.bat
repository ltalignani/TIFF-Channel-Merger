@echo off
set VIPSPATH=%LOCALAPPDATA%\vips\bin\vips.exe
set OUTPUT=%TEMP%\vips_tiffload.txt

echo === VIPS tiffload options === > "%OUTPUT%"
"%VIPSPATH%" tiffload >> "%OUTPUT%" 2>&1

type "%OUTPUT%"
