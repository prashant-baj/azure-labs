@echo off
REM ==========================================================================
REM  Junior SWAT Labs - reverse every change fix-company-proxy.cmd made.
REM  Double-click this file, or run  .\undo-company-proxy-fix.cmd  in this folder.
REM ==========================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProxyFix='undo'; Get-Content -Raw '.\fix-company-proxy.ps1' | Invoke-Expression"
echo.
pause
