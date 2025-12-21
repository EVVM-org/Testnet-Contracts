@echo off
setlocal

:: Detect OS and architecture
for /f "tokens=2 delims==" %%A in ('wmic os get osarchitecture /value') do set ARCH=%%A
set OS=windows

:: Determine the executable
if "%OS%"=="windows" (
    if "%ARCH%"=="64-bit" (
        set EXECUTABLE=.executables\evvm-windows-x64.exe
    ) else (
        echo Unsupported architecture: %ARCH%
        exit /b 1
    )
) else (
    echo Unsupported platform: %OS%
    exit /b 1
)

:: Execute the binary
if exist %EXECUTABLE% (
    %EXECUTABLE% %*
) else (
    echo Executable not found: %EXECUTABLE%
    exit /b 1
)