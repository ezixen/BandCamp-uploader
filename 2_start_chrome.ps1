# 2) Start debug Chrome — log into Bandcamp once
# Profile: %LOCALAPPDATA%\BandCamp-Uploader\chrome-debug-profile
# (not inside the app folder — app folder stays deletable)
#
#   .\2_start_chrome.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_chrome_session.ps1")

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  $chrome = "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chrome)) {
  throw "Chrome not found. Install Google Chrome first."
}

# Drop legacy profile next to scripts if present (temp location)
Remove-BandCampLegacyLocalSecrets -Roots @($PSScriptRoot, (Join-Path $PSScriptRoot "app\BandCamp-Uploader"))

$userData = Ensure-BandCampChromeProfileWritable
Clear-BandCampChromeLocks

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2
  Write-Host "CDP already up on 9222 - using existing debug Chrome."
  Start-Process "https://ezixen.bandcamp.com/dashboard"
} catch {
  Write-Host "Starting debug Chrome..."
  Write-Host "  --remote-debugging-port=9222"
  Write-Host "  --remote-allow-origins=*"
  Write-Host "  --user-data-dir=$userData"

  Start-Process -FilePath $chrome -ArgumentList @(
    "--remote-debugging-port=9222",
    "--remote-allow-origins=*",
    "--user-data-dir=$userData",
    "https://bandcamp.com/login"
  )

  Start-Sleep -Seconds 2
  $ver = (Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 5).Content
  Write-Host "OK CDP:" $ver
}

Write-Host ""
Write-Host "Log into Bandcamp if needed (login kept under %LOCALAPPDATA%\BandCamp-Uploader)."
Write-Host "After uploads, session cleanup keeps login but clears caches/locks."
Write-Host "Full wipe (including login): .\5_cleanup.bat"
Write-Host "Optional title check:  .\3_check_titles.bat"
Write-Host "Upload draft:          .\4_bandcamp_uploader.bat"
