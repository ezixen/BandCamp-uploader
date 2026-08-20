# Build BandCamp-Uploader.exe (onedir) into app\BandCamp-Uploader\
# Uses newest available Python from C:/.venv (or PATH). Bundles that runtime into the EXE.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File app\build_exe.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root "bandcamp_upload_album.py"))) {
  throw "Run from musicstuff repo (bandcamp_upload_album.py missing)."
}

$py = "C:\.venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
  $py = (Get-Command python -ErrorAction Stop).Source
}

Write-Host "Build Python: $py"
& $py -c "import sys; print(sys.version)"
& $py -m pip install -q "pyinstaller>=6.0" "websocket-client>=1.6.0"

# Prefer this repo on PYTHONPATH so we never freeze a stale chrome_debug from another clone.
# Also keep the publish folder OFF the path (it may contain an old extracted chrome_debug.py).
$env:PYTHONPATH = $root
$env:PYTHONDONTWRITEBYTECODE = "1"
& $py -c "import chrome_debug, inspect; print('chrome_debug:', inspect.getfile(chrome_debug)); assert hasattr(chrome_debug, 'remember_started_chrome'), dir(chrome_debug)"

$appPy = Join-Path $PSScriptRoot "bandcamp_app.py"
$prices = Join-Path $root "prices.txt"
$outRoot = Join-Path $PSScriptRoot "_build_out"
$distName = "BandCamp-Uploader"
$final = Join-Path $PSScriptRoot $distName
$work = Join-Path $PSScriptRoot "_pyi_work"
$spec = Join-Path $PSScriptRoot "_pyi_spec"

foreach ($p in @($outRoot, $work, $spec)) {
  if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}

$addData = "$prices;."
& $py -m PyInstaller `
  --noconfirm `
  --clean `
  --console `
  --name $distName `
  --paths $root `
  --distpath $outRoot `
  --workpath $work `
  --specpath $spec `
  --add-data $addData `
  --hidden-import websocket `
  --hidden-import chrome_debug `
  $appPy

if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed: $LASTEXITCODE" }

$built = Join-Path $outRoot $distName
$outExe = Join-Path $built "BandCamp-Uploader.exe"
if (-not (Test-Path $outExe)) { throw "Missing $outExe" }

Copy-Item $prices (Join-Path $built "prices.txt") -Force
@"
BandCamp Uploader (EXE)
=======================

Latest always (GitHub):
  https://github.com/ezixen/BandCamp-uploader
  https://github.com/ezixen/BandCamp-uploader/releases/latest
  EXE pack: https://github.com/ezixen/BandCamp-uploader/releases/latest/download/BandCamp-Uploader-exe.zip

1. Double-click BandCamp-Uploader.exe
2. Log into Bandcamp in the Chrome window that opens (once)
3. Paste an album folder path, Enter — repeat for more albums
4. Review drafts in Chrome; publish yourself

Needs: Google Chrome installed.
Edits: prices.txt in this folder (album= / track=)
Chrome login: %LOCALAPPDATA%\BandCamp-Uploader\ (kept between runs; never beside this EXE)
On quit: debug Chrome stops; caches/temp cleared; this folder stays deletable
"@ | Set-Content (Join-Path $built "HOW_TO_RUN.txt") -Encoding UTF8

# Publish into app\BandCamp-Uploader (never copy local-secrets — profile is under LocalAppData)
New-Item -ItemType Directory -Force -Path $final | Out-Null
& robocopy $built $final /E /XD local-secrets /NFL /NDL /NJH /NJS /nc /ns /np /R:2 /W:1 | Out-Null
Copy-Item (Join-Path $built "BandCamp-Uploader.exe") (Join-Path $final "BandCamp-Uploader.exe") -Force
Copy-Item (Join-Path $built "prices.txt") (Join-Path $final "prices.txt") -Force
Copy-Item (Join-Path $built "HOW_TO_RUN.txt") (Join-Path $final "HOW_TO_RUN.txt") -Force

# Scrub any leftover local-secrets beside the published EXE (old builds / locked Chrome)
& $py -c @"
import sys
from pathlib import Path
sys.path.insert(0, r'$root')
from chrome_debug import scrub_app_folder_side_effects, stop_chrome_using_profile
stop_chrome_using_profile()
scrub_app_folder_side_effects(Path(r'$final'))
print('scrubbed', r'$final')
"@

Write-Host ""
Write-Host "OK built: $(Join-Path $final 'BandCamp-Uploader.exe')"
Get-ChildItem $final | Select-Object Name, Length | Format-Table -AutoSize
if (Test-Path (Join-Path $final "local-secrets")) {
  Write-Host "WARNING: local-secrets still present under publish folder" -ForegroundColor Yellow
}
