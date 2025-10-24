@echo off
set VIPSPATH=%LOCALAPPDATA%\vips\bin\vips.exe

echo === All VIPS operations ===
"%VIPSPATH%" -l > %TEMP%\vips_all_ops.txt 2>&1

echo.
echo === Operations containing 'set' ===
findstr /i "set" %TEMP%\vips_all_ops.txt
echo.
echo === Operations containing 'copy' ===
findstr /i "copy" %TEMP%\vips_all_ops.txt
echo.
echo === Operations containing 'header' or 'meta' ===
findstr /i "header meta" %TEMP%\vips_all_ops.txt
