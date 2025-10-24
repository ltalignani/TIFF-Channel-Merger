@echo off
:: TIFF Channel Merger Launcher for Windows - OME Version
:: This batch file launches the OME-TIFF compatible PowerShell GUI application

title TIFF Channel Merger - OME Version

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

:: Launch the OME-TIFF compatible PowerShell application
echo Starting TIFF Channel Merger (OME Version)...
echo.
echo This version includes:
echo - Fixed UTF-8 encoding for proper French accent display
echo - Channel naming feature for QuPath integration
echo - OME-TIFF metadata support with Python integration
echo - Corrected VIPS bandjoin command syntax
echo - Enhanced diagnostic logging and error handling
echo - Automatic OME-XML generation for QuPath compatibility
echo.
echo Optional: Install Python with PIL/Pillow for full OME-TIFF support
echo   pip install pillow
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0TIFF-Channel-Merger-UltraFinal-v2.ps1"

:: Pause if there was an error
if errorlevel 1 (
    echo.
    echo An error occurred while running the application.
    pause
)