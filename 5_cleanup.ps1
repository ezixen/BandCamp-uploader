# Stop debug Chrome; clear caches/locks; remove legacy local-secrets.
# By default KEEPS Bandcamp login under %LOCALAPPDATA%\BandCamp-Uploader.
#
#   .\5_cleanup.ps1              # keep login
#   .\5_cleanup.ps1 -RemoveLogin # wipe login too

param(
  [switch]$RemoveLogin
)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "_chrome_session.ps1")

Write-Host "=== BandCamp Uploader cleanup ==="
if ($RemoveLogin) {
  Write-Host "Mode: remove caches + Bandcamp login"
} else {
  Write-Host "Mode: remove caches/locks/temp; KEEP Bandcamp login"
}

$roots = @(
  $PSScriptRoot,
  (Join-Path $PSScriptRoot "app\BandCamp-Uploader")
)
$n = Invoke-BandCampSessionCleanup -AppRoots $roots -RemoveLogin:$RemoveLogin
Write-Host "Stopped $n Chrome process(es)."
Write-Host ""
Write-Host "Done. You can delete the BandCamp-uploader app folder in File Explorer."
if (-not $RemoveLogin) {
  Write-Host "Login still in: $env:LOCALAPPDATA\BandCamp-Uploader"
  Write-Host "To wipe login too: .\5_cleanup.ps1 -RemoveLogin"
}
pause
