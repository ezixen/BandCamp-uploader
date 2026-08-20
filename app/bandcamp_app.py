"""
BandCamp Uploader — single EXE / console app.

No Python install required when frozen. Needs Google Chrome on the PC.
Paste album folder paths one at a time; drafts only (never publishes).

Chrome login stays under %%LOCALAPPDATA%%\\BandCamp-Uploader.
After each quit we stop debug Chrome, clear caches/locks/temp, and remove any
legacy local-secrets next to the EXE — login cookies are kept.
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
from pathlib import Path

_HERE = Path(__file__).resolve().parent
_ROOT = _HERE.parent if (_HERE.parent / "bandcamp_upload_album.py").is_file() else _HERE
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from bandcamp_upload_album import (  # noqa: E402
    album_title_from_folder,
    app_dir,
    cdp_alive,
    largest_jpg,
    load_prices,
    numbered_wavs,
    run_upload,
    title_from_filename,
)
from chrome_debug import (  # noqa: E402
    chrome_data_root,
    chrome_profile_dir,
    cleanup_after_use,
    prepare_chrome_profile,
    register_chrome_cleanup_on_exit,
)

LOGIN_URL = "https://bandcamp.com/login"


def find_chrome() -> Path:
    candidates = [
        Path(os.environ.get("PROGRAMFILES", r"C:\Program Files"))
        / "Google/Chrome/Application/chrome.exe",
        Path(os.environ.get("LOCALAPPDATA", ""))
        / "Google/Chrome/Application/chrome.exe",
        Path(os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)"))
        / "Google/Chrome/Application/chrome.exe",
    ]
    for p in candidates:
        if p.is_file():
            return p
    raise SystemExit(
        "Google Chrome not found.\n"
        "Install Chrome from https://www.google.com/chrome/ then run this again."
    )


def ensure_prices_file() -> None:
    prices = app_dir() / "prices.txt"
    if prices.is_file():
        return
    prices.write_text(
        "# Default Bandcamp draft prices (edit anytime)\nalbum=9.99\ntrack=0.99\n",
        encoding="utf-8",
    )
    print(f"Created {prices}", flush=True)


def ensure_debug_chrome() -> None:
    if cdp_alive():
        print("Debug Chrome already on port 9222.", flush=True)
        return
    chrome = find_chrome()
    profile = prepare_chrome_profile()
    print("Starting debug Chrome...", flush=True)
    print(f"  {chrome}", flush=True)
    print(f"  profile: {profile}", flush=True)
    print(f"  (login kept in {chrome_data_root()}; caches cleared when you quit)", flush=True)
    subprocess.Popen(
        [
            str(chrome),
            "--remote-debugging-port=9222",
            "--remote-allow-origins=*",
            f"--user-data-dir={profile}",
            LOGIN_URL,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    for _ in range(20):
        time.sleep(0.5)
        if cdp_alive():
            print("OK — CDP is up. Log into Bandcamp in that Chrome window if needed.", flush=True)
            return
    raise SystemExit("Chrome started but CDP on 9222 did not become ready.")


def preview_folder(folder: Path) -> None:
    album_price, track_price = load_prices()
    wavs = numbered_wavs(folder)
    cover = largest_jpg(folder)
    print("Album title:", album_title_from_folder(folder), flush=True)
    print("Cover:", cover.name, flush=True)
    print(f"Prices: album={album_price}  track={track_price}", flush=True)
    print("Tracks:", len(wavs), flush=True)
    for w in wavs:
        print(" ", w.name, "->", title_from_filename(w.name), flush=True)


def upload_one(folder: Path) -> None:
    album_price, track_price = load_prices()
    preview_folder(folder)
    if not cdp_alive():
        ensure_debug_chrome()
    run_upload(folder, album_price, track_price)


def read_path() -> Path | None:
    print(flush=True)
    print("Paste one album folder path (or blank / q to quit):", flush=True)
    raw = input("> ").strip().strip('"').strip("'")
    if not raw or raw.lower() in {"q", "quit", "exit"}:
        return None
    p = Path(raw)
    if not p.is_dir():
        print(f"ERROR: not a folder: {p}", flush=True)
        return Path("__retry__")
    return p.resolve()


def main() -> int:
    roots = (app_dir(),)
    register_chrome_cleanup_on_exit(*roots)
    print("=== BandCamp Uploader (EXE / console) ===", flush=True)
    print("Drafts only — you publish in Bandcamp yourself.", flush=True)
    print(f"App folder: {app_dir()}", flush=True)
    print(f"Chrome profile (login kept): {chrome_profile_dir()}", flush=True)
    ensure_prices_file()
    find_chrome()
    ensure_debug_chrome()
    print(flush=True)
    print("After you are logged into Bandcamp, paste album folders one at a time.", flush=True)
    print("On quit: debug Chrome stops; caches/temp cleared; Bandcamp login kept.", flush=True)

    while True:
        folder = read_path()
        if folder is None:
            break
        if folder.name == "__retry__":
            continue
        try:
            upload_one(folder)
            print("OK — draft ready. Review in Chrome.", flush=True)
        except SystemExit as e:
            print(f"ERROR: {e}", flush=True)
        except Exception as e:
            print(f"ERROR: {e}", flush=True)

    n = cleanup_after_use(*roots, keep_login=True)
    print(f"Cleanup done (stopped {n} Chrome process(es); login kept). Bye.", flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        cleanup_after_use(app_dir(), keep_login=True)
        print("\nInterrupted — cleaned up (login kept).", flush=True)
        raise SystemExit(130)
