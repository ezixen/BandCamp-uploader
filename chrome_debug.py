"""
Shared Chrome debug-profile helpers (EXE + scripts).

Profile lives under %%LOCALAPPDATA%%\\BandCamp-Uploader so the unpacked
app folder can always be deleted without fighting Chrome lock files.

After each use we stop debug Chrome, drop locks/caches/temp, and remove any
legacy local-secrets next to the app — but we KEEP Bandcamp login cookies.
"""
from __future__ import annotations

import atexit
import os
import shutil
import subprocess
import time
from pathlib import Path

PROFILE_ROOT_NAME = "BandCamp-Uploader"
PROFILE_DIR_NAME = "chrome-debug-profile"

# Names/paths to delete after a session (ephemeral). Login/session data is kept.
_EPHEMERAL_DIR_NAMES = {
    "Cache",
    "Code Cache",
    "GPUCache",
    "GrShaderCache",
    "GraphiteDawnCache",
    "ShaderCache",
    "DawnCache",
    "DawnWebGPUCache",
    "Media Cache",
    "VideoDecodeStats",
    "Crashpad",
    "CrashpadMetrics-active.pma",
    "BrowserMetrics",
    "optimization_guide_hint_cache_store",
    "Download Service",
    "Safe Browsing",
    "File System",
    "blob_storage",
    "Service Worker",
}
# Never delete these (Bandcamp login / prefs)
_KEEP_NAME_HINTS = (
    "Cookies",
    "Login Data",
    "Preferences",
    "Secure Preferences",
    "Web Data",
    "Network",
    "Local Storage",
    "Session Storage",
    "IndexedDB",
)


def chrome_data_root() -> Path:
    local = os.environ.get("LOCALAPPDATA") or str(Path.home() / "AppData" / "Local")
    return Path(local) / PROFILE_ROOT_NAME


def chrome_profile_dir() -> Path:
    return chrome_data_root() / PROFILE_DIR_NAME


def ensure_user_writable(path: Path) -> Path:
    """Create path and grant the current user full control (recursive)."""
    path.mkdir(parents=True, exist_ok=True)
    user = os.environ.get("USERNAME") or os.environ.get("USER") or ""
    if user:
        subprocess.run(
            ["icacls", str(path), "/grant", f"{user}:(OI)(CI)F", "/T", "/C", "/Q"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    try:
        path.chmod(0o700)
    except OSError:
        pass
    return path


def stop_chrome_using_profile(profile: Path | None = None) -> int:
    """Stop chrome.exe processes whose command line references our profile."""
    profile = profile or chrome_profile_dir()
    markers = [
        str(profile).replace("/", "\\"),
        f"{PROFILE_ROOT_NAME}\\{PROFILE_DIR_NAME}",
        "local-secrets\\chrome-debug-profile",
    ]
    likes = " -or ".join(
        f"($_.CommandLine -like '*{m.replace(chr(39), '')}*')" for m in markers
    )
    ps = f"""
$ErrorActionPreference = 'SilentlyContinue'
$n = 0
Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" | ForEach-Object {{
  if ($_.CommandLine -and ({likes})) {{
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    $n++
  }}
}}
Write-Output $n
"""
    try:
        r = subprocess.run(
            [
                os.environ.get("SystemRoot", r"C:\Windows")
                + r"\System32\WindowsPowerShell\v1.0\powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-Command",
                ps,
            ],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
        time.sleep(0.8)
        try:
            return int((r.stdout or "0").strip().splitlines()[-1])
        except (ValueError, IndexError):
            return 0
    except (OSError, subprocess.TimeoutExpired):
        return 0


def clear_chrome_lock_files(profile: Path | None = None) -> None:
    profile = profile or chrome_profile_dir()
    if not profile.is_dir():
        return
    for pattern in ("**/LOCK", "**/SingletonLock", "**/SingletonCookie", "**/SingletonSocket"):
        for p in profile.glob(pattern):
            try:
                p.unlink(missing_ok=True)
            except OSError:
                pass


def _is_keep(path: Path) -> bool:
    name = path.name
    for hint in _KEEP_NAME_HINTS:
        if name == hint or name.startswith(hint):
            return True
    return False


def prune_ephemeral_chrome_cache(profile: Path | None = None) -> None:
    """Delete caches/temp under the profile; keep cookies / login / prefs."""
    profile = profile or chrome_profile_dir()
    if not profile.is_dir():
        return
    for child in list(profile.iterdir()):
        if _is_keep(child):
            continue
        if child.is_dir() and child.name in _EPHEMERAL_DIR_NAMES:
            shutil.rmtree(child, ignore_errors=True)
        elif child.is_file() and child.suffix.lower() in {".tmp", ".log", ".old", ".pma"}:
            try:
                child.unlink(missing_ok=True)
            except OSError:
                pass
    # Default/ profile subfolder (Chrome often nests here)
    default = profile / "Default"
    if default.is_dir():
        for child in list(default.iterdir()):
            if _is_keep(child):
                continue
            if child.is_dir() and child.name in _EPHEMERAL_DIR_NAMES:
                shutil.rmtree(child, ignore_errors=True)
            elif child.is_file() and child.name in {"LOCK", "TransportSecurity"}:
                try:
                    child.unlink(missing_ok=True)
                except OSError:
                    pass


def force_remove_tree(path: Path) -> bool:
    """Best-effort delete of a directory tree on any drive (takeown + robocopy empty mirror)."""
    if not path.exists():
        return True
    path = path.resolve()
    stop_chrome_using_profile(path if path.name == PROFILE_DIR_NAME else path / PROFILE_DIR_NAME)
    # Also stop chrome if command line mentions this exact path
    marker = str(path).replace("/", "\\")
    try:
        subprocess.run(
            [
                os.environ.get("SystemRoot", r"C:\Windows")
                + r"\System32\WindowsPowerShell\v1.0\powershell.exe",
                "-NoProfile",
                "-Command",
                f"""
$ErrorActionPreference='SilentlyContinue'
Get-CimInstance Win32_Process | Where-Object {{
  $_.CommandLine -and $_.CommandLine -like '*{marker.replace(chr(39),'')}*'
}} | ForEach-Object {{ Stop-Process -Id $_.ProcessId -Force }}
""",
            ],
            capture_output=True,
            timeout=60,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass
    time.sleep(0.8)
    ensure_user_writable(path)
    shutil.rmtree(path, ignore_errors=True)
    if not path.exists():
        return True
    # robocopy empty-dir mirror (works when rd/Remove-Item fail)
    empty = Path(os.environ.get("TEMP", ".")) / f"empty_del_{os.getpid()}_{int(time.time())}"
    try:
        empty.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            ["robocopy", str(empty), str(path), "/MIR", "/R:2", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np"],
            capture_output=True,
            check=False,
        )
        subprocess.run(["cmd", "/c", "rd", "/s", "/q", str(path)], capture_output=True, check=False)
    finally:
        shutil.rmtree(empty, ignore_errors=True)
    if not path.exists():
        return True
    # Rename aside so parent can be deleted; schedule delete on reboot as last resort
    renamed = path.with_name(path.name + ".__delete_me__")
    try:
        if renamed.exists():
            shutil.rmtree(renamed, ignore_errors=True)
        path.rename(renamed)
        path = renamed
    except OSError:
        pass
    try:
        import ctypes

        MOVEFILE_DELAY_UNTIL_REBOOT = 0x4
        # Schedule each top-level file if still present
        for p in [path] + (list(path.rglob("*")) if path.exists() else []):
            if p.exists() and p.is_file():
                ctypes.windll.kernel32.MoveFileExW(str(p), None, MOVEFILE_DELAY_UNTIL_REBOOT)
        if path.exists():
            ctypes.windll.kernel32.MoveFileExW(str(path), None, MOVEFILE_DELAY_UNTIL_REBOOT)
    except Exception:
        pass
    shutil.rmtree(path, ignore_errors=True)
    return not path.exists()


def remove_legacy_app_local_secrets(*roots: Path) -> None:
    """Old profile lived next to the EXE/scripts — remove so the app folder deletes cleanly on any drive."""
    names = ("local-secrets", "local-secrets.to_delete", "local-secrets.__delete_me__")
    for root in roots:
        if not root:
            continue
        for name in names:
            legacy = Path(root) / name
            if legacy.exists():
                force_remove_tree(legacy)


def scrub_app_folder_side_effects(app_root: Path) -> None:
    """On start and exit: wipe any junk Chrome left beside the EXE (any drive)."""
    remove_legacy_app_local_secrets(app_root)
    # Chrome sometimes drops crashpad next to cwd if misconfigured — remove known junk names
    for name in ("Crashpad", "chrome_debug.log", "debug.log"):
        p = Path(app_root) / name
        if p.is_dir():
            force_remove_tree(p)
        elif p.is_file():
            try:
                p.unlink(missing_ok=True)
            except OSError:
                pass


def prepare_chrome_profile() -> Path:
    d = ensure_user_writable(chrome_profile_dir())
    clear_chrome_lock_files(d)
    return d


def cleanup_after_use(*app_roots: Path, keep_login: bool = True) -> int:
    """
    End-of-session cleanup:
    - stop debug Chrome for our profile
    - clear locks + ephemeral caches
    - remove legacy local-secrets under app folders (any drive)
    - keep Bandcamp login when keep_login=True
    """
    n = stop_chrome_using_profile()
    time.sleep(0.8)
    clear_chrome_lock_files()
    if keep_login:
        prune_ephemeral_chrome_cache()
        ensure_user_writable(chrome_profile_dir())
    else:
        root = chrome_data_root()
        if root.is_dir():
            force_remove_tree(root)
    for r in app_roots:
        scrub_app_folder_side_effects(Path(r))
    return n


def register_chrome_cleanup_on_exit(*app_roots: Path) -> None:
    roots = tuple(app_roots)

    def _cleanup() -> None:
        cleanup_after_use(*roots, keep_login=True)

    atexit.register(_cleanup)
