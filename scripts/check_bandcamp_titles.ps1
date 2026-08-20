# 2/3 — Preview album title / cover / track titles (no browser upload).
#
# Usage:
#   .\scripts\check_bandcamp_titles.ps1
#   .\scripts\check_bandcamp_titles.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"

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

Write-Host "Checking titles for: $AlbumFolder"
& $python -u $script $AlbumFolder --dry-run
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Looks good? Upload draft with:"
Write-Host "  .\scripts\upload_bandcamp_album.ps1 `"$AlbumFolder`""
