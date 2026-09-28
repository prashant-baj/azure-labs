@echo off
REM ==========================================================================
REM  Junior SWAT Labs - 02 - Azure resources test: deploy and check
REM
REM  Runs run-test.ps1 as COMMANDS rather than as a .ps1 file, so a company
REM  PowerShell execution policy cannot block it.
REM  Double-click this file, or run  .\run-test.cmd  in this folder.
REM ==========================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$Mode='apply'; Get-Content -Raw '.\run-test.ps1' | Invoke-Expression"
echo.
pause
