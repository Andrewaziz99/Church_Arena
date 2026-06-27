# Fix: CMake cannot find Visual Studio / force correct generator
# Run as Administrator
# NOTE: VS 2026 Community (v18) is legitimately installed on this machine.
# This script does NOT touch VS18 registry entries.

Write-Host "=== Installed Visual Studio versions ==="
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    & $vsWhere -all -format text 2>&1 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  vswhere not found"
}

Write-Host ""
Write-Host "=== Clearing CMAKE_GENERATOR override ==="
# Remove any forced generator - let Flutter auto-detect VS18/2026
[System.Environment]::SetEnvironmentVariable("CMAKE_GENERATOR", $null, "Machine")
[System.Environment]::SetEnvironmentVariable("CMAKE_GENERATOR", $null, "User")
Write-Host "  Cleared CMAKE_GENERATOR env var (Flutter will auto-detect VS18 2026)"

Write-Host ""
Write-Host "=== Cleaning Flutter build ==="
Set-Location "D:\WORK\Church\church_arena"
& "D:\develop\flutter\bin\flutter.bat" clean 2>&1 | ForEach-Object { Write-Host "  $_" }
if (Test-Path "build") {
    Remove-Item "build" -Recurse -Force
    Write-Host "  build\ folder deleted"
}

Write-Host ""
Write-Host "=============================="
Write-Host "Done. Open a NEW terminal (not Admin) and run:"
Write-Host "  cd D:\WORK\Church\church_arena"
Write-Host "  powershell -ExecutionPolicy Bypass -File diagnose.ps1"
Write-Host "=============================="
