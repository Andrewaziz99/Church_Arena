# Fix: Flutter Device Daemon Crash + file handles error
# Run as Administrator

$flutterSdk  = "D:\develop\flutter"
$projectDir  = "D:\WORK\Church\church_arena"
$androidSdk  = "$env:LOCALAPPDATA\Android\Sdk"
$adbPath     = "$androidSdk\platform-tools\adb.exe"
$flutter     = "$flutterSdk\bin\flutter.bat"

# ── 1. Add AV exclusions (file handle exhaustion is usually Defender) ─────────
Write-Host "[1/5] Adding Windows Defender exclusions..."
$paths = @($flutterSdk, $projectDir, $androidSdk,
           "$env:APPDATA\Google",
           "$env:LOCALAPPDATA\Google",
           "$env:USERPROFILE\.dart",
           "$env:USERPROFILE\.pub-cache")
foreach ($p in $paths) {
    if (Test-Path $p) {
        Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
        Write-Host "  Excluded: $p"
    }
}
Add-MpPreference -ExclusionProcess "flutter.bat"      -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "dart.exe"         -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "dartaotruntime.exe" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "adb.exe"          -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "studio64.exe"     -ErrorAction SilentlyContinue
Write-Host "  AV exclusions set"

# ── 2. Kill stale processes ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Killing stale dart/adb/flutter processes..."
foreach ($proc in @("dart","adb","flutter_tools","dartaotruntime")) {
    Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done"

# ── 3. Reset Flutter cache (ensures dartaotruntime.exe exists) ────────────────
Write-Host ""
Write-Host "[3/5] Resetting Flutter cache..."
$cache = "$flutterSdk\bin\cache"
if (Test-Path $cache) {
    Remove-Item $cache -Recurse -Force
    Write-Host "  Deleted old cache"
}
Write-Host "  Running flutter precache (downloads dart runtime + devtools)..."
& $flutter precache 2>&1 | ForEach-Object { Write-Host "  $_" }

# ── 4. Verify dartaotruntime.exe now exists ───────────────────────────────────
Write-Host ""
Write-Host "[4/5] Verifying key binaries..."
$bins = @(
    "$flutterSdk\bin\cache\dart-sdk\bin\dartaotruntime.exe",
    "$flutterSdk\bin\cache\dart-sdk\bin\dart.exe",
    "$flutterSdk\bin\cache\artifacts\engine\windows-x64\flutter_windows.dll"
)
foreach ($b in $bins) {
    if (Test-Path $b) {
        Write-Host "  OK: $b"
    } else {
        Write-Host "  MISSING: $b  <-- run flutter precache manually"
    }
}

# ── 5. Restart ADB ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Restarting ADB server..."
if (Test-Path $adbPath) {
    & $adbPath kill-server 2>&1 | Out-Null
    Start-Sleep -Seconds 1
    & $adbPath start-server 2>&1 | Out-Null
    Write-Host "  ADB restarted"
} else {
    Write-Host "  ADB not found (skipping)"
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=============================="
Write-Host "Script done. Do these steps in Android Studio:"
Write-Host ""
Write-Host "1. Help - Invalidate Caches - Invalidate and Restart"
Write-Host "2. After restart:"
Write-Host "   Settings - Languages and Frameworks - Flutter"
Write-Host "   SDK path: D:\develop\flutter"
Write-Host "3. Settings - Languages and Frameworks - Dart"
Write-Host "   SDK path: D:\develop\flutter\bin\cache\dart-sdk"
Write-Host "4. Settings - Plugins - update Flutter and Dart plugins"
Write-Host "5. Restart Android Studio one more time"
Write-Host "=============================="
