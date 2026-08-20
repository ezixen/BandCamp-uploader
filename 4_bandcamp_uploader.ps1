# 4) Upload album draft to Bandcamp (does not publish)
#
#   .\4_bandcamp_uploader.ps1
#   .\4_bandcamp_uploader.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"

param(
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$AlbumFolder
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_common.ps1")

$AlbumFolder = Resolve-AlbumFolder $AlbumFolder
$python = Resolve-PythonExe
$script = Get-UploaderPy

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2
} catch {
  throw "Chrome CDP not on 9222. Run .\2_start_chrome.ps1 and log into Bandcamp first."
}

Write-Host "Python: $python"
Write-Host "Uploading draft for: $AlbumFolder"
Write-Host "(cover = largest jpg/jpeg, prices from prices.txt, title-only, no publish)"
& $python -u $script $AlbumFolder
exit $LASTEXITCODE