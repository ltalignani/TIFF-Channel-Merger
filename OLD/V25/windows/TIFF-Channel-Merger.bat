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
echo - Fixed UTF-8 BOM encoding for proper French accent display
echo - Channel naming feature for QuPath integration
echo - Channel order selection and management
echo - Enhanced diagnostic logging and error handling
echo - Corrected VIPS bandjoin command syntax
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0TIFF-Channel-Merger.ps1"

:: Pause if there was an error
if errorlevel 1 (
    echo.
    echo An error occurred while running the application.
    pause
)