# 3) Optional — preview titles / cover / prices (no upload)
#
#   .\3_check_titles.ps1
#   .\3_check_titles.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"

param(
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$AlbumFolder
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_common.ps1")

$AlbumFolder = Resolve-AlbumFolder $AlbumFolder
$python = Resolve-PythonExe
$script = Get-UploaderPy

Write-Host "Python: $python"
Write-Host "Checking titles for: $AlbumFolder"
& $python -u $script $AlbumFolder --dry-run
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Looks good? Upload draft with:"
Write-Host "  .\4_bandcamp_uploader.ps1 `"$AlbumFolder`""