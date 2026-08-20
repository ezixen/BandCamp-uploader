# Shared Chrome profile path + session cleanup for PowerShell steps.
# Dot-source from 2 / 4 / 5. Keeps Bandcamp login; clears locks/caches/legacy folders.

function Get-BandCampChromeProfileDir {
  Join-Path $env:LOCALAPPDATA "BandCamp-Uploader\chrome-debug-profile"
}

function Ensure-BandCampChromeProfileWritable {
  $dir = Get-BandCampChromeProfileDir
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $me = $env:USERNAME
  cmd /c "icacls `"$dir`" /grant `"$me`:(OI)(CI)F`" /T /C /Q" >$null 2>&1
  return $dir
}

function Stop-BandCampDebugChrome {
  $markers = @(
    "BandCamp-Uploader\chrome-debug-profile",
    "local-secrets\chrome-debug-profile",
    "chrome-debug-profile"
  )
  $n = 0
  Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
    $cmd = $_.CommandLine
    if (-not $cmd) { return }
    foreach ($m in $markers) {
      if ($cmd -like "*$m*") {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        $n++
        break
      }
    }
  }
  return $n
}

function Clear-BandCampChromeLocks {
  $dir = Get-BandCampChromeProfileDir
  if (-not (Test-Path -LiteralPath $dir)) { return }
  Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @("LOCK", "SingletonLock", "SingletonCookie", "SingletonSocket") } |
    Remove-Item -Force -ErrorAction SilentlyContinue
}

function Remove-BandCampEphemeralCache {
  $ephemeral = @(
    "Cache", "Code Cache", "GPUCache", "GrShaderCache", "GraphiteDawnCache",
    "ShaderCache", "DawnCache", "DawnWebGPUCache", "Media Cache", "Crashpad",
    "Service Worker", "blob_storage", "File System"
  )
  $keep = @("Cookies", "Login Data", "Preferences", "Secure Preferences", "Web Data", "Network", "Local Storage", "Session Storage", "IndexedDB")
  foreach ($base in @((Get-BandCampChromeProfileDir), (Join-Path (Get-BandCampChromeProfileDir) "Default"))) {
    if (-not (Test-Path -LiteralPath $base)) { continue }
    Get-ChildItem -LiteralPath $base -Force -ErrorAction SilentlyContinue | ForEach-Object {
      if ($keep -contains $_.Name) { return }
      if ($_.PSIsContainer -and ($ephemeral -contains $_.Name)) {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
  }
}

function Remove-BandCampLegacyLocalSecrets {
  param([string[]]$Roots)
  foreach ($r in $Roots) {
    if (-not $r) { continue }
    $legacy = Join-Path $r "local-secrets"
    if (-not (Test-Path -LiteralPath $legacy)) { continue }
    Write-Host "Removing legacy: $legacy"
    $me = $env:USERNAME
    # Stop chrome using this path first
    Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
      if ($_.CommandLine -and ($_.CommandLine -like "*$legacy*")) {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
      }
    }
    Start-Sleep -Seconds 1
    cmd /c "takeown /F `"$legacy`" /R /D Y" >$null 2>&1
    cmd /c "icacls `"$legacy`" /grant `"$me`":F /T /C /Q" >$null 2>&1
    cmd /c "icacls `"$legacy`" /grant Administrators:F /T /C /Q" >$null 2>&1
    Get-ChildItem -LiteralPath $legacy -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
      try { $_.Attributes = 'Normal' } catch {}
    }
    cmd /c "rd /s /q `"$legacy`"" >$null 2>&1
    if (Test-Path -LiteralPath $legacy) {
      Remove-Item -LiteralPath $legacy -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

function Invoke-BandCampSessionCleanup {
  param(
    [string[]]$AppRoots = @($PSScriptRoot),
    [switch]$RemoveLogin
  )
  $n = Stop-BandCampDebugChrome
  Start-Sleep -Seconds 1
  Clear-BandCampChromeLocks
  if ($RemoveLogin) {
    $root = Join-Path $env:LOCALAPPDATA "BandCamp-Uploader"
    if (Test-Path -LiteralPath $root) {
      $me = $env:USERNAME
      cmd /c "takeown /F `"$root`" /R /D Y" >$null 2>&1
      cmd /c "icacls `"$root`" /grant `"$me`":F /T /C /Q" >$null 2>&1
      Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
  } else {
    Remove-BandCampEphemeralCache
    Ensure-BandCampChromeProfileWritable | Out-Null
  }
  Remove-BandCampLegacyLocalSecrets -Roots $AppRoots
  return $n
}
