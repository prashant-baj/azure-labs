@echo off
REM ==========================================================================
REM  Junior SWAT Labs - local toolchain check (launcher for locked-down Windows)
REM
REM  Runs check-prereqs.ps1 as COMMANDS rather than as a .ps1 file, so a
REM  corporate PowerShell execution policy (even one set by Group Policy) does
REM  not block it. Just double-click this file, or run  .\check-prereqs.cmd
REM ==========================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Raw '%~dp0check-prereqs.ps1' | Invoke-Expression"
echo.
pause
