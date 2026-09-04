@echo off
title SYED SADIQ POLY CLINIC & HOSPITAL MANAGEMENT SYSTEM
echo ========================================================
echo   SYED SADIQ POLY CLINIC & HOSPITAL MANAGEMENT SYSTEM
echo ========================================================
echo.
echo Launching Clinic Software...
echo Data is saved 100% offline in local hardware storage.
echo.
start "" "%~dp0index.html" || start chrome "%~dp0index.html" || start msedge "%~dp0index.html"
exit

