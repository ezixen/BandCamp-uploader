# 1) First-time setup — elevated: winget Python + pip requirements
#
#   .\1_install.ps1
#   .\1_install.ps1 -DryRun

param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

if (-not (Test-IsAdmin)) {
  Write-Host "Requesting elevated PowerShell (Administrator) for install..."
  $argList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$PSCommandPath`""
  )
  if ($DryRun) { $argList += "-DryRun" }
  $exe = "pwsh"
  if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { $exe = "powershell.exe" }
  $proc = Start-Process -FilePath $exe -Verb RunAs -ArgumentList $argList -PassThru -Wait
  exit $proc.ExitCode
}

Write-Host "=== Bandcamp Uploader install (elevated) ==="
Write-Host "Repo: $repoRoot"
Write-Host ""

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
  throw "winget not found. Install App Installer from the Microsoft Store, then re-run."
}

$wingetArgs = @(
  "install",
  "-e",
  "--id", "Python.Python.3.13",
  "--accept-package-agreements",
  "--accept-source-agreements"
)

Write-Host "Would run / will run:"
Write-Host ("  winget " + ($wingetArgs -join " "))
Write-Host ""

if ($DryRun) {
  Write-Host "DryRun: reached elevated winget step - NOT installing."
  Write-Host "winget path: $($winget.Source)"
  winget --version
  Write-Host "DryRun OK."
  exit 0
}

Write-Host "Installing Python via winget (default location)..."
& winget @wingetArgs
Write-Host "winget exit: $LASTEXITCODE"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

function Find-Python {
  foreach ($cmd in @("python", "py")) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c) {
      try {
        if ($cmd -eq "py") {
          $exe = & py -3 -c "import sys; print(sys.executable)" 2>$null
          if ($exe) { return $exe.Trim() }
        } else {
          $ok = & $c.Source -c "import sys; print(sys.version)" 2>$null
          if ($ok) { return $c.Source }
        }
      } catch {}
    }
  }
  foreach ($p in @(
      "$env:LocalAppData\Programs\Python\Python313\python.exe",
      "$env:LocalAppData\Programs\Python\Python312\python.exe",
      "${env:ProgramFiles}\Python313\python.exe",
      "${env:ProgramFiles}\Python312\python.exe"
    )) {
    if (Test-Path $p) { return $p }
  }
  return $null
}

$python = Find-Python
if (-not $python) {
  throw "Python installed but not found on PATH. Open a new terminal and re-run .\1_install.ps1"
}

Write-Host "Using Python: $python"
& $python -m pip install --upgrade pip
$req = Join-Path $repoRoot "requirements.txt"
if (Test-Path $req) {
  & $python -m pip install -r $req
} else {
  & $python -m pip install "websocket-client>=1.6.0"
}

$prices = Join-Path $repoRoot "prices.txt"
if (-not (Test-Path $prices)) {
  $txt = @"
# Default Bandcamp draft prices (edit anytime)
album=9.99
track=0.99
"@
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($prices, $txt, $utf8)
  Write-Host "Created prices.txt"
}

Write-Host ""
Write-Host "Install complete."
Write-Host "Next: .\2_start_chrome.ps1  (log into Bandcamp once)"
Write-Host "Then:  .\4_bandcamp_uploader.ps1"
exit 0