@echo off
:: TIFF Channel Merger Launcher for Windows
:: This batch file launches the PowerShell GUI application

title TIFF Channel Merger

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
powershell.exe -ExecutionPolicy Bypass -File "%~dp0TIFF-Channel-Merger.ps1"

:: Pause if there was an error
if errorlevel 1 (
    echo.
    echo An error occurred while running the application.
    pause
)