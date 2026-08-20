# Bandcamp Uploader

**GitHub (latest always):** https://github.com/ezixen/BandCamp-uploader  
**[Latest release](https://github.com/ezixen/BandCamp-uploader/releases/latest)** · **[ZIP (scripts + EXE)](https://github.com/ezixen/BandCamp-uploader/releases/latest/download/BandCamp-uploader.zip)** · **[EXE only](https://github.com/ezixen/BandCamp-uploader/releases/latest/download/BandCamp-Uploader-exe.zip)**  

Unpack either ZIP → you get a **`BandCamp-uploader/`** folder (no need to create one).

---

Upload local album folders to Bandcamp as **drafts**. You review and publish yourself.

## Option A — EXE (easiest, no install)

1. Unpack and open **`BandCamp-uploader/app/BandCamp-Uploader/`** (ZIP already contains the `BandCamp-uploader` folder)
2. Double-click **`BandCamp-Uploader.exe`**
3. Log into Bandcamp in the Chrome window that opens (once per PC)
4. Paste one album folder path at a time; press Enter after each
5. Review drafts in Chrome — the app never publishes

Requires **Google Chrome**. Optional: edit `prices.txt` beside the exe.  

Chrome login profile is stored under **`%LOCALAPPDATA%\BandCamp-Uploader\`** (not inside the app folder), so you can delete the unpacked folder anytime.  
After each quit the app stops debug Chrome, clears caches/locks/temp, and removes leftover `local-secrets` — **Bandcamp login is kept**.  
Full wipe including login: **`5_cleanup.bat -RemoveLogin`** (or `.\5_cleanup.ps1 -RemoveLogin`).

Rebuild from source: `app/build_exe.ps1` (uses `C:/.venv` Python + PyInstaller).

---

## Option B — PowerShell scripts

| Step | File | Purpose |
|---|---|---|
| 0 | `0_associate_ps1.bat` | **Do this first** — bind `.ps1` to built-in Windows PowerShell and clear other handlers |
| 1 | `1_install.bat` / `.ps1` | Elevated install: **newest** winget Python 3.x (currently 3.14) + pip deps; skips install if 3.10+ already present |
| 2 | `2_start_chrome.bat` / `.ps1` | Debug Chrome; log in once (`%LOCALAPPDATA%\BandCamp-Uploader`) |
| 3 | `3_check_titles.bat` / `.ps1` | Optional title / cover / price preview |
| 4 | `4_bandcamp_uploader.bat` / `.ps1` | Upload album draft(s) |
| 5 | `5_cleanup.bat` / `.ps1` | Stop debug Chrome; clear caches; optional `-RemoveLogin` to wipe Bandcamp login too |

Prefer the **`.bat`** step files for double-click. They always call:

`%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`

Helpers: `_run_ps1.bat`, `_common.ps1`, `bandcamp_upload_album.py`, `prices.txt`, `requirements.txt`  
Short guide: [`how2use.txt`](how2use.txt)

### Step 0 — Windows PowerShell for `.ps1`

1. Double-click **`0_associate_ps1.bat`**
2. It **only** uses the default Windows PowerShell path (no pwsh hunt, no questions)
3. It clears prior BandCamp / Explorer “open with” entries for `.ps1` that it can remove
4. Then use **`1_install.bat`** … or the raw `.ps1` files

On some Windows 11 PCs Explorer may still show a picker once; the `.bat` twins and the EXE avoid that entirely.

---

## Multiple albums (script path)

Separate full folder paths with **`;`**:

```powershell
.\4_bandcamp_uploader.ps1 "d:\music\album1; d:\music\album2"
```

The EXE asks for one path per line instead.

---

## What it fills (per album)

- Album title, prices from `prices.txt`, largest jpg/jpeg cover  
- Numbered `.wav` files in order, title-only (`01. Artist - title.wav`)  
- **Save Album Draft** only — never Publish  

---

## File naming

```text
01. ezixen - intro.wav
```

Number → order · Artist stripped · Title kept · `_` → `?`

---

## Prices (`prices.txt`)

```text
album=9.99
track=0.99
```

---

## Safety

No publish · no passwords in repo · respect Bandcamp terms  

Latest: https://github.com/ezixen/BandCamp-uploader
