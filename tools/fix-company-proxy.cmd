@echo off
REM ==========================================================================
REM  Junior SWAT Labs - make the Azure CLI, Git and npm work behind a company
REM  proxy that inspects HTTPS. Changes nothing unless your network needs it.
REM
REM  Runs fix-company-proxy.ps1 as COMMANDS rather than as a .ps1 file, so a
REM  company PowerShell execution policy cannot block it.
REM  Double-click this file, or run  .\fix-company-proxy.cmd  in this folder.
REM ==========================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProxyFix='auto'; Get-Content -Raw '.\fix-company-proxy.ps1' | Invoke-Expression"
echo.
pause
