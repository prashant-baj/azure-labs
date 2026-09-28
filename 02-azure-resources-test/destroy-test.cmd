@echo off
REM ==========================================================================
REM  Junior SWAT Labs - 02 - Azure resources test: tear everything down
REM
REM  Same launcher as run-test.cmd, in destroy mode.
REM  Double-click this file, or run  .\destroy-test.cmd  in this folder.
REM ==========================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$Mode='destroy'; Get-Content -Raw '.\run-test.ps1' | Invoke-Expression"
echo.
pause
