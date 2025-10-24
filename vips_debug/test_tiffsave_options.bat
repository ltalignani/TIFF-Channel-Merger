@echo off
set VIPSPATH=%LOCALAPPDATA%\vips\bin\vips.exe
set OUTPUT=%TEMP%\tiffsave_options.txt

echo === VIPS tiffsave full options === > "%OUTPUT%"
"%VIPSPATH%" tiffsave >> "%OUTPUT%" 2>&1

type "%OUTPUT%"
echo.
echo.
echo === Searching for 'description' and 'properties' options ===
findstr /i "description properties imagedescription" "%OUTPUT%"
