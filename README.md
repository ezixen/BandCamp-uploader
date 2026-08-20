# Bandcamp Uploader

Upload one local album folder to Bandcamp as a **draft**. You review and publish yourself.

Flat layout — run the numbered scripts in order from this folder.

| Step | Script | Purpose |
|---|---|---|
| 1 | `1_install.ps1` | Elevated install: winget Python + pip deps |
| 2 | `2_start_chrome.ps1` | Debug Chrome; log in once (local profile) |
| 3 | `3_check_titles.ps1` | Optional title / cover / price preview |
| 4 | `4_bandcamp_uploader.ps1` | Upload album draft (no publish) |

Helpers (not steps): `_common.ps1`, `bandcamp_upload_album.py`, `prices.txt`, `requirements.txt`

Short human guide: [`how2use.txt`](how2use.txt)

---

## First-time setup

```powershell
cd path\to\BandCamp-uploader
.\1_install.ps1
```

Approve UAC. Installs Python 3.13 via winget (default path) and `websocket-client`.

Dry-run (elevate, reach winget, do not install):

```powershell
.\1_install.ps1 -DryRun
```

Then:

```powershell
.\2_start_chrome.ps1
```

Log into Bandcamp in that window. Login cookies stay in `local-secrets\chrome-debug-profile` (local only, not in git).

---

## Every upload

```powershell
.\2_start_chrome.ps1
.\3_check_titles.ps1 "d:\path\to\album"          # optional
.\4_bandcamp_uploader.ps1 "d:\path\to\album"
```

Or omit the path and paste when prompted.

---

## What it fills

- Album title (from folder name)
- Album / track prices from `prices.txt`
- Cover = largest `.jpg` / `.jpeg` in the folder
- Numbered `.wav` files only, one at a time
- Track titles only (see naming below)
- **Save Album Draft** — never Publish

---

## File naming

```text
01. ezixen - intro.wav
```

1. Number first (sort order)  
2. Artist name  
3. ` - `  
4. Track title  
5. `.wav`

Bandcamp title becomes `intro`. `_` in titles becomes `?`.

---

## Prices

Edit `prices.txt` anytime; read on every run:

```text
album=9.99
track=0.99
```

---

## Safety

- No publish  
- No passwords in the repo  
- Respect Bandcamp terms  

Repo: https://github.com/ezixen/BandCamp-uploader