# 3/3 — Upload one Bandcamp album as a draft (does not publish).
# Requires debug Chrome from start_bandcamp_chrome.ps1 + Bandcamp login.
#
# Usage:
#   .\scripts\upload_bandcamp_album.ps1
#   .\scripts\upload_bandcamp_album.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"

param(
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$AlbumFolder
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$AlbumFolder = Resolve-AlbumFolder $AlbumFolder
$python = Resolve-PythonExe
$script = Get-UploaderPy

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2
} catch {
  throw "Chrome CDP not on 9222. Run .\scripts\start_bandcamp_chrome.ps1 and log into Bandcamp first."
}

Write-Host "Python: $python"
Write-Host "Uploading draft for: $AlbumFolder"
Write-Host "(cover = largest jpg/jpeg, prices from prices.txt, title-only, no publish)"
& $python -u $script $AlbumFolder
exit $LASTEXITCODE
