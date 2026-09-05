@echo off
setlocal enabledelayedexpansion
title "SYED SADIQ POLY CLINIC & HOSPITAL MANAGEMENT SYSTEM"
color 0A
cls

echo =======================================================================
echo     SYED SADIQ POLY CLINIC & HOSPITAL MANAGEMENT SYSTEM (OFFLINE)
echo =======================================================================
echo.
echo Launching Clinic Software in Google Chrome...
echo Please wait a moment...
echo.

set "APP_DIR=%~dp0"
set "INDEX_FILE=%APP_DIR%index.html"

rem 1. Check standard Windows Chrome installation paths
set "CHROME_PATH="

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
) else if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
) else if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%LocalAppData%\Google\Chrome\Application\chrome.exe"
) else if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)

if defined CHROME_PATH (
    echo [SUCCESS] Found Google Chrome. Opening Software...
    start "" "!CHROME_PATH!" --allow-file-access-from-files --disable-web-security --user-data-dir="%TEMP%\ClinicAppChrome" "%INDEX_FILE%"
    exit /b 0
)

rem 2. Try 'chrome' command if registered in PATH
where chrome >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Opening Software in Google Chrome...
    start "" chrome --allow-file-access-from-files --disable-web-security --user-data-dir="%TEMP%\ClinicAppChrome" "%INDEX_FILE%"
    exit /b 0
)

rem 3. Try MS Edge / Firefox if Chrome is not found
where msedge >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Opening Software in Microsoft Edge...
    start "" msedge --allow-file-access-from-files "%INDEX_FILE%"
    exit /b 0
)

rem 4. Fallback to default browser
echo [NOTICE] Opening Software...
start "" "%INDEX_FILE%"
exit /b 0
