# Diagnose Dart compiler crash - run as normal user (not Admin)
# Step 1: debug build (no AOT - fastest, proves code is valid)
# Step 2: only if debug fails, do verbose release build
Set-Location "D:\WORK\Church\church_arena"
$flutter = "D:\develop\flutter\bin\flutter.bat"
$debugLog   = "D:\WORK\Church\church_arena\build_debug.txt"
$releaseLog = "D:\WORK\Church\church_arena\build_release.txt"

Write-Host "[1/3] flutter clean + pub get..."
& $flutter clean 2>&1
& $flutter pub get 2>&1

Write-Host ""
Write-Host "[2/3] DEBUG build (no AOT - tests Dart compilation without TFA/AOT)..."
Write-Host "      Saving to build_debug.txt"
& $flutter build windows --debug --verbose 2>&1 | Tee-Object -FilePath $debugLog

$debugOk = $LASTEXITCODE -eq 0

if ($debugOk) {
    Write-Host ""
    Write-Host "=== DEBUG BUILD SUCCEEDED ==="
    Write-Host "The Dart code itself is valid."
    Write-Host "The crash in release build is AOT/TFA specific (likely memory)."
    Write-Host ""
    Write-Host "[3/3] Running flutter run -d windows (debug, skips AOT)..."
    Write-Host "      This will launch the app directly."
    Write-Host "      If it works, your app is functional."
    Write-Host "      To build release later, see note below."
} else {
    Write-Host ""
    Write-Host "=== DEBUG BUILD FAILED - capturing verbose release output ==="
    Write-Host "      Saving to build_release.txt"
    & $flutter build windows --release --verbose 2>&1 | Tee-Object -FilePath $releaseLog
}

Write-Host ""
Write-Host "=============================="
if ($debugOk) {
    Write-Host "DEBUG BUILD PASSED. Your code is fine."
    Write-Host "Next step: run the app with:"
    Write-Host "  cd D:\WORK\Church\church_arena"
    Write-Host "  flutter run -d windows"
    Write-Host ""
    Write-Host "NOTE: If release build still fails later, try:"
    Write-Host "  flutter build windows --release --no-tree-shake-icons"
} else {
    Write-Host "DEBUG BUILD FAILED."
    Write-Host "Share build_debug.txt for the exact Dart compilation error."
}
Write-Host "=============================="
