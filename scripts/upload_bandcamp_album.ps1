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

function Resolve-AlbumFolder([string]$PathIn) {
  if ([string]::IsNullOrWhiteSpace($PathIn)) {
    $PathIn = Read-Host "Paste album folder path"
  }
  $PathIn = $PathIn.Trim().Trim('"').Trim("'")
  if ([string]::IsNullOrWhiteSpace($PathIn)) {
    throw "No folder path given."
  }
  if (-not (Test-Path -LiteralPath $PathIn)) {
    throw "Folder not found: $PathIn"
  }
  return (Resolve-Path -LiteralPath $PathIn).Path
}

$AlbumFolder = Resolve-AlbumFolder $AlbumFolder
$python = "C:/.venv/Scripts/python.exe"
$script = Join-Path $PSScriptRoot "bandcamp_upload_album.py"

if (-not (Test-Path $python)) { throw "Python not found: $python" }
if (-not (Test-Path $script)) { throw "Uploader not found: $script" }

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2
} catch {
  throw "Chrome CDP not on 9222. Run .\scripts\start_bandcamp_chrome.ps1 and log into Bandcamp first."
}

Write-Host "Uploading draft for: $AlbumFolder"
Write-Host "(cover = largest jpg, album 9.99, tracks 0.99, title-only, no publish)"
& $python -u $script $AlbumFolder
exit $LASTEXITCODE
