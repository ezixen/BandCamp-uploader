# Build BandCamp-Uploader.exe (onedir) into app\BandCamp-Uploader\
# Run from repo root with:  C:/.venv/Scripts/python.exe -m pip install pyinstaller websocket-client
# Then:  powershell -File app\build_exe.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root "bandcamp_upload_album.py"))) {
  $root = $PSScriptRoot
  if (-not (Test-Path (Join-Path $root "bandcamp_upload_album.py"))) {
    throw "Run from musicstuff repo (bandcamp_upload_album.py missing)."
  }
}

$py = "C:\.venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
  $py = (Get-Command python -ErrorAction Stop).Source
}

Write-Host "Python: $py"
& $py -m pip install -q "pyinstaller>=6.0" "websocket-client>=1.6.0"

$appPy = Join-Path $PSScriptRoot "bandcamp_app.py"
$prices = Join-Path $root "prices.txt"
$dist = Join-Path $PSScriptRoot "BandCamp-Uploader"
$work = Join-Path $PSScriptRoot "_pyi_work"
$spec = Join-Path $PSScriptRoot "_pyi_spec"

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
if (Test-Path $spec) { Remove-Item $spec -Recurse -Force }

# Windows add-data: source;dest
$addData = "$prices;."

& $py -m PyInstaller `
  --noconfirm `
  --clean `
  --console `
  --name "BandCamp-Uploader" `
  --paths $root `
  --distpath $PSScriptRoot `
  --workpath $work `
  --specpath $spec `
  --add-data $addData `
  --hidden-import websocket `
  --collect-all websocket `
  $appPy

if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed: $LASTEXITCODE" }

$outExe = Join-Path $dist "BandCamp-Uploader.exe"
if (-not (Test-Path $outExe)) { throw "Missing $outExe" }

# Ensure prices.txt beside exe (editable)
Copy-Item $prices (Join-Path $dist "prices.txt") -Force

# Short how-to next to exe
@"
BandCamp Uploader (EXE)
=======================
1. Double-click BandCamp-Uploader.exe
2. Log into Bandcamp in the Chrome window that opens (once)
3. Paste an album folder path, Enter — repeat for more albums
4. Review drafts in Chrome; publish yourself

Needs: Google Chrome installed.
Edits: prices.txt in this folder (album= / track=)
Profile: local-secrets\chrome-debug-profile (created on first run)
"@ | Set-Content (Join-Path $dist "HOW_TO_RUN.txt") -Encoding UTF8

Write-Host ""
Write-Host "OK built: $outExe"
Get-ChildItem $dist | Select-Object Name, Length | Format-Table -AutoSize
