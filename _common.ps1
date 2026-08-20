# Shared helpers (not a numbered step). Dot-sourced by steps 3 and 4.

function Resolve-PythonExe {
  $candidates = [System.Collections.Generic.List[string]]::new()
  function Add-Cand([string]$p) {
    if ($p -and (Test-Path -LiteralPath $p) -and -not $candidates.Contains($p)) { [void]$candidates.Add($p) }
  }

  Add-Cand "C:\.venv\Scripts\python.exe"
  foreach ($cmd in @("python", "python3")) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c -and $c.Source) { Add-Cand $c.Source }
  }
  if (Get-Command "py" -ErrorAction SilentlyContinue) {
    try {
      $viaPy = & py -3 -c "import sys; print(sys.executable)" 2>$null
      if ($viaPy) { Add-Cand $viaPy.Trim() }
    } catch {}
  }
  $pf = ${env:ProgramFiles}
  $local = $env:LOCALAPPDATA
  foreach ($p in @(
      "$local\Programs\Python\Python313\python.exe",
      "$local\Programs\Python\Python312\python.exe",
      "$pf\Python313\python.exe",
      "$pf\Python312\python.exe",
      "$pf\Python314\python.exe"
    )) { Add-Cand $p }

  $fallback = $null
  foreach ($p in $candidates) {
    try {
      $hasWs = & $p -c "import websocket, sys; print('OK' if sys.version_info >= (3, 10) else 'NO')" 2>$null
      if ($hasWs -match "OK") { return $p }
      $ver = & $p -c "import sys; print('OK' if sys.version_info >= (3, 10) else 'NO')" 2>$null
      if ($ver -match "OK" -and -not $fallback) { $fallback = $p }
    } catch {}
  }
  if ($fallback) {
    Write-Warning "Python found but websocket-client missing: $fallback"
    Write-Warning "Run .\1_install.ps1 or: pip install -r requirements.txt"
    return $fallback
  }
  throw "Python 3.10+ not found on PATH. Run .\1_install.ps1 first (elevated)."
}

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

function Get-UploaderPy {
  $p = Join-Path $PSScriptRoot "bandcamp_upload_album.py"
  if (-not (Test-Path -LiteralPath $p)) {
    throw "Uploader not found: $p"
  }
  return $p
}