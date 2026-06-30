@echo off
cd /d "%~dp0"
set FLUTTER=D:\develop\flutter_3.41.2\bin\flutter.bat

echo [1/3] Running flutter pub get to regenerate plugin list...
"%FLUTTER%" pub get
if errorlevel 1 (
    echo ERROR: flutter pub get failed. Aborting.
    pause
    exit /b 1
)

echo [2/3] Cleaning stale CMake build cache...
rmdir /s /q "build\windows\x64" 2>nul
echo Done.

echo [3/3] Building...
"%FLUTTER%" build windows --debug
pause
