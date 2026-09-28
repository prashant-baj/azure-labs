@echo off
REM ==========================================================================
REM  Junior SWAT Labs - 00 - Azure CLI access check
REM
REM  Runs az-access-check.ps1 as COMMANDS rather than as a .ps1 file, so a
REM  company PowerShell execution policy cannot block it.
REM  Double-click this file, or run  .\az-access-check.cmd  in this folder.
REM ==========================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Raw '.\az-access-check.ps1' | Invoke-Expression"
echo.
pause
