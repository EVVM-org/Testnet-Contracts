@echo off
setlocal enabledelayedexpansion

:: Get the directory where the script is located
set "SCRIPT_DIR=%~dp0"

:: Detect architecture
set "ARCH="
for /f "tokens=2 delims==" %%A in ('wmic os get osarchitecture /value 2^>nul') do (
    set "ARCH=%%A"
)

:: Remove any trailing spaces/carriage returns
set "ARCH=%ARCH: =%"

:: Determine the executable
if "%ARCH%"=="64-bit" (
    set "EXECUTABLE=%SCRIPT_DIR%.executables\evvm-windows-x64.exe"
) else if "%ARCH%"=="32-bit" (
    echo Unsupported architecture: 32-bit Windows is not supported.
    exit /b 1
) else (
    echo Unable to detect architecture. Defaulting to x64.
    set "EXECUTABLE=%SCRIPT_DIR%.executables\evvm-windows-x64.exe"
)

:: Execute the binary
if exist "%EXECUTABLE%" (
    "%EXECUTABLE%" %*
) else (
    echo Executable not found: %EXECUTABLE%
    echo Please ensure the executable exists in the .executables folder.
    exit /b 1
)