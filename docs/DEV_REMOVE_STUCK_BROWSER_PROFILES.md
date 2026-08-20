# DEV ONLY — Remove stuck automated-browser profile folders

**Audience:** Cursor / agents on a secondary PC that still has undeletable leftovers from *older* BandCamp Uploader builds (or Playwright/Chrome automation under `C:\Temp` / `D:\Temp`).

**Not for end users.** Product fix (v1.5.1+): Chrome profile lives only under `%LOCALAPPDATA%\BandCamp-Uploader`; the EXE must never create `local-secrets` beside itself. Do **not** document this in `how2use.txt` / user README.

---

## What went wrong (old builds)

Older builds used `--user-data-dir=...\local-secrets\chrome-debug-profile` **next to the EXE/scripts**. Chrome left `LOCK` / DB files that Windows refuses to delete even after reboot if a process still holds them, or if ACLs need `takeown`. Same class of junk appears as:

- `...\BandCamp-uploader\**\local-secrets`
- `C:\Temp\chrome-debug-profile`
- `C:\Temp\playwright_chromiumdev_profile-*`
- `C:\Temp\chrome-canary*`

## Method (do this on the stuck PC)

1. Close Cursor browser tools / BandCamp EXE if open.
2. Write the script below to e.g. `%TEMP%\force_remove_browser_temps.ps1` (ASCII only).
3. Run **elevated** (UAC), killing automation Chrome first:

```powershell
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
Start-Process -FilePath $ps -Verb RunAs -ArgumentList @(
  '-NoProfile','-ExecutionPolicy','Bypass',
  '-File', $scriptPath,
  '-Elevated','-KillAllChrome','-NoPause'
) -Wait
```

4. Confirm targets are gone; if a few remain, reboot once and re-run.
5. Optional: delete `%LOCALAPPDATA%\BandCamp-Uploader` only if you also want to wipe Bandcamp login (`-AlsoWipeBandCampLogin`).

### Extra scan roots

If leftovers sit next to an unpacked ZIP, add those folders to `$scanRoots` in the script (or pass them by editing the list): any path containing `BandCamp-uploader` / `BandCamp-Uploader` with a `local-secrets` child.

---

## Script to create and run

Save as `force_remove_browser_temps.ps1`:

```powershell
# DEV: force-remove stuck chrome/playwright profile folders.
# Does NOT touch the normal Chrome user profile under Local\Google\Chrome.

param(
  [switch]$AlsoWipeBandCampLogin,
  [switch]$WhatIf,
  [switch]$NoPause,
  [switch]$Elevated,
  [switch]$KillAllChrome
)

$ErrorActionPreference = "Continue"

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($id)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($Elevated -and -not $isAdmin) {
  $arg = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", "`"$PSCommandPath`"",
    "-Elevated", "-NoPause"
  )
  if ($AlsoWipeBandCampLogin) { $arg += "-AlsoWipeBandCampLogin" }
  if ($KillAllChrome) { $arg += "-KillAllChrome" }
  if ($WhatIf) { $arg += "-WhatIf" }
  $exe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
  $p = Start-Process -FilePath $exe -Verb RunAs -ArgumentList $arg -PassThru -Wait
  exit $p.ExitCode
}

function Stop-AutomationBrowsers {
  $n = 0
  if ($KillAllChrome) {
    Get-Process chrome,chromium,msedge -ErrorAction SilentlyContinue | ForEach-Object {
      Write-Host ("Stop ALL browser PID {0} {1}" -f $_.Id, $_.ProcessName)
      Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
      $n++
    }
    Start-Sleep -Seconds 2
    return $n
  }
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Name -match '^(chrome|chromium|msedge|playwright|firefox)\.exe$' -and
      $_.CommandLine -and (
        $_.CommandLine -match 'user-data-dir|remote-debugging|chrome-debug|local-secrets|playwright_chromium|puppeteer|BandCamp-Uploader|chrome-canary'
      )
    } |
    ForEach-Object {
      Write-Host ("Stop PID {0} {1}" -f $_.ProcessId, $_.Name)
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
      $n++
    }
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
      $_.CommandLine -and (
        $_.CommandLine -match 'chrome-debug-profile|playwright_chromiumdev_profile|local-secrets\\chrome|BandCamp-Uploader\\chrome|Temp\\chrome|Temp\\playwright'
      )
    } |
    ForEach-Object {
      Write-Host ("Stop helper PID {0} {1}" -f $_.ProcessId, $_.Name)
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
      $n++
    }
  Start-Sleep -Seconds 2
  return $n
}

function Grant-FullControl([string]$Path) {
  $me = $env:USERNAME
  cmd /c "takeown /F `"$Path`" /R /D Y" >$null 2>&1
  cmd /c "icacls `"$Path`" /grant `"$me`":(F) /T /C /Q" >$null 2>&1
  cmd /c "icacls `"$Path`" /grant Administrators:(F) /T /C /Q" >$null 2>&1
  cmd /c "icacls `"$Path`" /grant SYSTEM:(F) /T /C /Q" >$null 2>&1
  Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.Attributes = "Normal" } catch {}
  }
}

function Remove-TreeRobocopy([string]$Path) {
  $empty = Join-Path $env:TEMP ("empty_del_" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $empty | Out-Null
  try {
    & robocopy $empty $Path /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np >$null 2>&1
    cmd /c "rd /s /q `"$Path`"" >$null 2>&1
  } finally {
    cmd /c "rd /s /q `"$empty`"" >$null 2>&1
  }
}

function Remove-TreeForced([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $true }
  if ($WhatIf) {
    Write-Host ("WhatIf: would remove {0}" -f $Path)
    return $true
  }
  Write-Host ("Removing: {0}" -f $Path)
  Grant-FullControl $Path
  cmd /c "rd /s /q `"$Path`"" >$null 2>&1
  if (-not (Test-Path -LiteralPath $Path)) { Write-Host "  OK"; return $true }
  Remove-TreeRobocopy $Path
  if (-not (Test-Path -LiteralPath $Path)) { Write-Host "  OK (robocopy)"; return $true }
  $renamed = "$Path.__delete_me__"
  try {
    Rename-Item -LiteralPath $Path -NewName ([IO.Path]::GetFileName($renamed)) -Force -ErrorAction Stop
    Write-Host ("  Renamed to {0}" -f $renamed)
    Grant-FullControl $renamed
    Remove-TreeRobocopy $renamed
    if (-not (Test-Path -LiteralPath $renamed)) { Write-Host "  OK after rename"; return $true }
  } catch {
    Write-Host ("  FAIL: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
  }
  return $false
}

function Get-AutomationTempTargets {
  $list = New-Object System.Collections.Generic.List[string]
  $namePatterns = @(
    '^chrome-debug-profile$',
    '^chrome-canary',
    '^chrome-wiwm',
    '^ela-chrome',
    '^merge-purge-.*chrome',
    '^playwright_chromium',
    '^puppeteer_',
    '^selenium-',
    '^local-secrets$',
    '^local-secrets\.to_delete$',
    '^local-secrets\.__delete_me__$',
    '\.to_delete$',
    '\.__delete_me__$'
  )

  $scanRoots = @(
    "C:\Temp", "C:\temp", "D:\Temp", "D:\temp",
    $env:TEMP,
    $PSScriptRoot
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

  # Also find unpacked BandCamp-uploader trees with local-secrets
  foreach ($drive in @("C:\", "D:\", "E:\")) {
    if (-not (Test-Path $drive)) { continue }
    Get-ChildItem $drive -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match 'BandCamp' } |
      ForEach-Object {
        $scanRoots += $_.FullName
        $nested = Join-Path $_.FullName "app\BandCamp-Uploader"
        if (Test-Path $nested) { $scanRoots += $nested }
      }
  }

  foreach ($root in ($scanRoots | Select-Object -Unique)) {
    Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | ForEach-Object {
      foreach ($pat in $namePatterns) {
        if ($_.Name -match $pat) { [void]$list.Add($_.FullName); break }
      }
    }
    foreach ($extra in @(
        (Join-Path $root "local-secrets"),
        (Join-Path $root "app\BandCamp-Uploader\local-secrets")
      )) {
      if (Test-Path -LiteralPath $extra) { [void]$list.Add($extra) }
    }
  }

  if ($AlsoWipeBandCampLogin) {
    $bc = Join-Path $env:LOCALAPPDATA "BandCamp-Uploader"
    if (Test-Path -LiteralPath $bc) { [void]$list.Add($bc) }
  }

  return ($list | Select-Object -Unique)
}

Write-Host "=== Force-remove automated browser temp folders ==="
if ($isAdmin) { Write-Host "Running elevated." } else { Write-Host "Not elevated (use -Elevated if Access Denied)." }
$stopped = Stop-AutomationBrowsers
Write-Host ("Stopped {0} browser process(es)." -f $stopped)

$targets = @(Get-AutomationTempTargets)
if ($targets.Count -eq 0) {
  Write-Host "Nothing matching to remove."
} else {
  Write-Host ("Targets: {0}" -f $targets.Count)
  $ok = 0; $fail = 0
  foreach ($t in $targets) {
    if (Remove-TreeForced $t) { $ok++ } else { $fail++ }
  }
  Write-Host ("Removed/cleared: {0}  Still stuck: {1}" -f $ok, $fail)
  if ($fail -gt 0 -and -not $isAdmin) {
    Write-Host "Re-run with -Elevated -KillAllChrome" -ForegroundColor Yellow
  }
}

if (-not $AlsoWipeBandCampLogin) {
  Write-Host ("Bandcamp login kept at: {0}\BandCamp-Uploader" -f $env:LOCALAPPDATA)
}
Write-Host "Done."
if (-not $WhatIf -and -not $NoPause) { pause }
```

---

## Agent checklist

- [ ] Script written to disk (UTF-8 / ASCII quotes — no smart dashes)
- [ ] Run with `-Elevated -KillAllChrome -NoPause`
- [ ] Report remaining paths (should be none)
- [ ] Do **not** add cleanup tools back into the public ZIP / user docs
- [ ] Product regression: new EXE must print profile under `AppData\Local\BandCamp-Uploader` and leave no `local-secrets` beside the EXE
