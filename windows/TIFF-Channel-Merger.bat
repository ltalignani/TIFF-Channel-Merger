@echo off
:: TIFF Channel Merger Launcher for Windows
:: This batch file launches the PowerShell GUI application

title TIFF Channel Merger

:: Set console encoding to UTF-8 for proper character display
chcp 65001 >nul

:: Check if PowerShell is available
powershell.exe -Command "exit" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell is not available on this system.
    echo Please install PowerShell to run this application.
    pause
    exit /b 1
)

:: Launch the PowerShell application
echo Starting TIFF Channel Merger...
echo.
echo This version includes:
echo - FIXED: No more crashes with 4+ large images!
echo - Uses tiffload --unlimited to bypass 50MB TIFF limit
echo - Intermediate processing in .v format (no memory constraints)
echo - Converts to pyramidal TIFF only at the final step
echo - Optimized for large TIFF files with minimal RAM usage
echo - Channel naming feature for QuPath integration
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0TIFF-Channel-Merger.ps1"

:: Pause if there was an error
if errorlevel 1 (
    echo.
    echo An error occurred while running the application.
    pause
)