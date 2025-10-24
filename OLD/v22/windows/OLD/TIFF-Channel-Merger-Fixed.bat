@echo off
:: TIFF Channel Merger Launcher for Windows - Fixed Version
:: This batch file launches the corrected PowerShell GUI application

title TIFF Channel Merger - Fixed Version

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

:: Launch the corrected PowerShell application
echo Starting TIFF Channel Merger (Fixed Version)...
echo.
echo This version includes:
echo - Fixed character encoding for French accents
echo - Updated VIPS download URLs
echo - Improved error handling
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0TIFF-Channel-Merger-Fixed.ps1"

:: Pause if there was an error
if errorlevel 1 (
    echo.
    echo An error occurred while running the application.
    pause
)