# 1/3 — Start visible Chrome with remote debugging for Bandcamp automation.
# Required: port 9222 + --remote-allow-origins=* (else CDP websockets get 403).
#
# Usage:
#   .\scripts\start_bandcamp_chrome.ps1
# Then log into Bandcamp in that window (once per profile). Login stays local.

$ErrorActionPreference = "Stop"

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  $chrome = "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chrome)) {
  throw "Chrome not found. Install Google Chrome first."
}

$root = Split-Path -Parent $PSScriptRoot
$userData = Join-Path $root "local-secrets\chrome-debug-profile"
New-Item -ItemType Directory -Force -Path $userData | Out-Null

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2
  Write-Host "CDP already up on 9222 — using existing debug Chrome."
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
Write-Host "Log into Bandcamp if needed (password stays in this local Chrome profile only)."
Write-Host "Optional title check:  .\scripts\check_bandcamp_titles.ps1"
Write-Host "Upload draft:          .\scripts\upload_bandcamp_album.ps1"
