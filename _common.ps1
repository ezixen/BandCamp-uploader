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

function Split-AlbumPathInput([string]$PathIn) {
  # Newlines / | / ; always separate.
  # Comma separates only when the next piece looks like a Windows path (D:\... or "D:\...).
  $normalized = $PathIn -replace '[\r\n]+', ';'
  $chunks = [regex]::Split($normalized, '\s*;\s*|\s*\|\s*|\s*,\s*(?=[A-Za-z]:\\|"[A-Za-z]:\\)')
  $out = @()
  foreach ($c in $chunks) {
    $t = $c.Trim().Trim('"').Trim("'")
    if ($t) { $out += $t }
  }
  return $out
}

function Resolve-AlbumFolders([string]$PathIn) {
  if ([string]::IsNullOrWhiteSpace($PathIn)) {
    Write-Host "Paste one album folder path, or several separated by ; (or , between drive paths)."
    Write-Host 'Example: d:\music\album1; d:\music\album2'
    $PathIn = Read-Host "Path(s)"
  }

  $rawParts = Split-AlbumPathInput $PathIn
  if ($rawParts.Count -eq 0) {
    throw "No folder path given."
  }

  $ok = New-Object System.Collections.Generic.List[string]
  $errors = New-Object System.Collections.Generic.List[string]

  foreach ($part in $rawParts) {
    if (-not (Test-Path -LiteralPath $part)) {
      $msg = "BAD PATH (not found): $part"
      $errors.Add($msg) | Out-Null
      Write-Host "ERROR: $msg" -ForegroundColor Red
      continue
    }
    $item = Get-Item -LiteralPath $part -ErrorAction SilentlyContinue
    if (-not $item -or -not $item.PSIsContainer) {
      $msg = "BAD PATH (not a folder): $part"
      $errors.Add($msg) | Out-Null
      Write-Host "ERROR: $msg" -ForegroundColor Red
      continue
    }
    $resolved = (Resolve-Path -LiteralPath $part).Path
    if (-not $ok.Contains($resolved)) { $ok.Add($resolved) | Out-Null }
  }

  return [pscustomobject]@{
    Folders = @($ok)
    Errors  = @($errors)
  }
}

function Get-UploaderPy {
  $p = Join-Path $PSScriptRoot "bandcamp_upload_album.py"
  if (-not (Test-Path -LiteralPath $p)) {
    throw "Uploader not found: $p"
  }
  return $p
}