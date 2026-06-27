# Permanent fix for Android Studio vmoptions + Flutter daemon + DevTools
# Run as Administrator

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = "-Xms256m`n-Xmx2048m`n-XX:ReservedCodeCacheSize=512m`n-XX:+UseConcMarkSweepGC`n-XX:SoftRefLRUPolicyMSPerMB=50`n-ea`n-XX:CICompilerCount=2`n-Dfile.encoding=UTF-8`n"
$flutterSdk = "D:\develop\flutter"

function Fix-File($path) {
    if (-not (Test-Path $path)) {
        Write-Host "  Not found (skipped): $path"
        return
    }
    Set-ItemProperty $path -Name IsReadOnly -Value $false
    Copy-Item $path "$path.bak" -Force
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Set-ItemProperty $path -Name IsReadOnly -Value $true
    Write-Host "  Fixed and locked: $path"
}

# ── 1. Fix vmoptions ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[1/5] Fixing Android Studio vmoptions..."
Fix-File "C:\Program Files\Android\Android Studio\bin\studio64.exe.vmoptions"

$found = Get-ChildItem "$env:APPDATA\Google" -Recurse -Filter "studio64.exe.vmoptions" -ErrorAction SilentlyContinue
if ($found) {
    foreach ($f in $found) { Fix-File $f.FullName }
} else {
    Write-Host "  No user vmoptions found (OK)"
}

# ── 2. Set system UTF-8 ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Setting system UTF-8 environment..."
[System.Environment]::SetEnvironmentVariable("JAVA_TOOL_OPTIONS", "-Dfile.encoding=UTF-8", "Machine")
Write-Host "  JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8 set"

# ── 3. Clear Android Studio caches ───────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Clearing Android Studio caches..."
Get-Item "$env:LOCALAPPDATA\Google\AndroidStudio*\caches" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
    Write-Host "  Cleared: $($_.FullName)"
}
Get-Item "$env:LOCALAPPDATA\Google\AndroidStudio*\log" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
    Write-Host "  Cleared: $($_.FullName)"
}

# ── 4. Reset Flutter SDK cache (fixes dartaotruntime.exe + DevTools) ─────────
Write-Host ""
Write-Host "[4/5] Resetting Flutter SDK cache..."
$flutterCache = "$flutterSdk\bin\cache"
if (Test-Path $flutterCache) {
    Remove-Item $flutterCache -Recurse -Force
    Write-Host "  Deleted: $flutterCache"
} else {
    Write-Host "  Cache not found at $flutterCache"
}

Write-Host "  Re-downloading Flutter tools (this takes a minute)..."
$env:Path = "$flutterSdk\bin;" + $env:Path
& "$flutterSdk\bin\flutter.bat" precache 2>&1 | ForEach-Object { Write-Host "  $_" }

# ── 5. Reinstall DevTools ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Reinstalling Flutter DevTools..."
& "$flutterSdk\bin\flutter.bat" pub global activate devtools 2>&1 | ForEach-Object { Write-Host "  $_" }

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=============================="
Write-Host "All done. Final steps:"
Write-Host "  1. Relaunch Android Studio"
Write-Host "  2. Settings - Languages and Frameworks - Flutter"
Write-Host "     Flutter SDK path: D:\develop\flutter"
Write-Host "  3. Settings - Languages and Frameworks - Dart"
Write-Host "     Dart SDK path: D:\develop\flutter\bin\cache\dart-sdk"
Write-Host "  4. Restart Android Studio once more"
Write-Host "=============================="
