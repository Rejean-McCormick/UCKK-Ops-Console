@echo off
setlocal EnableExtensions

REM ============================================================
REM UCKK Ops Console - Windows launcher
REM ============================================================
REM Double-click this file to launch the application.
REM
REM ExecutionPolicy Bypass applies ONLY to this PowerShell process.
REM It does not modify the execution policy stored for the user
REM or for the machine.
REM ============================================================

chcp 65001 >nul

set "APP_ROOT=%~dp0"
set "ENTRYPOINT=%APP_ROOT%START_UCKK_OPS_CONSOLE.ps1"

echo.
echo ============================================================
echo UCKK Ops Console
echo ============================================================
echo App root:
echo %APP_ROOT%
echo.

if not exist "%ENTRYPOINT%" (
    echo ERROR
    echo The application entry point was not found:
    echo %ENTRYPOINT%
    echo.
    echo Make sure this file is located in:
    echo %APP_ROOT%
    echo.
    pause
    exit /b 1
)

where pwsh.exe >nul 2>nul
if errorlevel 1 (
    echo ERROR
    echo PowerShell 7 was not found.
    echo.
    echo UCKK Ops Console requires PowerShell 7.
    echo.
    echo Install PowerShell 7, then relaunch this file.
    echo Suggested command:
    echo winget install Microsoft.PowerShell
    echo.
    pause
    exit /b 1
)

cd /d "%APP_ROOT%"

pwsh.exe ^
  -NoLogo ^
  -NoProfile ^
  -ExecutionPolicy Bypass ^
  -File "%ENTRYPOINT%" %*

set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo UCKK Ops Console exited with an error.
    echo Exit code: %EXITCODE%
    echo.
    echo Check the reports and logs folders:
    echo %APP_ROOT%reports
    echo %APP_ROOT%logs
    echo.
    pause
)

exit /b %EXITCODE%
