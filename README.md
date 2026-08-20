# Bandcamp Uploader

**[Download ZIP](https://github.com/ezixen/BandCamp-uploader/releases/latest/download/BandCamp-uploader.zip)** — latest release (unpack, then start at `1_install.ps1`)

---

Upload one or more local album folders to Bandcamp as **drafts**. You review and publish yourself.

| Step | Script | Purpose |
|---|---|---|
| 1 | `1_install.ps1` | Elevated install: winget Python + pip deps |
| 2 | `2_start_chrome.ps1` | Debug Chrome; log in once (local profile) |
| 3 | `3_check_titles.ps1` | Optional title / cover / price preview |
| 4 | `4_bandcamp_uploader.ps1` | Upload album draft(s) (no publish) |

Helpers: `_common.ps1`, `bandcamp_upload_album.py`, `prices.txt`, `requirements.txt`  
Short guide: [`how2use.txt`](how2use.txt)

---

## Multiple albums in one run

Paste **several full folder paths** separated by **`;`** (recommended).  
A **`,`** also works when it sits between two drive paths (`D:\...`).

```powershell
.\4_bandcamp_uploader.ps1 "d:\music\album1; d:\music\album2; d:\music\album3"
```

Or omit the argument and paste when prompted.

The script processes albums **one after another**. For each path it reports:

- **BAD PATH** — missing or not a folder (skipped)
- **UPLOAD FAILED** — exception or non-zero exit for that album
- **OK** — draft finished for that album

A summary at the end lists successes and every error. Exit code is non-zero if anything failed or was invalid.

Same multi-path rules apply to `.\3_check_titles.ps1`.

---

## First-time setup

```powershell
.\1_install.ps1
.\2_start_chrome.ps1
```

Log into Bandcamp in the debug Chrome window (cookies stay in `local-secrets\chrome-debug-profile`).

---

## Every upload

```powershell
.\2_start_chrome.ps1
.\3_check_titles.ps1 "d:\path\a; d:\path\b"     # optional
.\4_bandcamp_uploader.ps1 "d:\path\a; d:\path\b"
```

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

https://github.com/ezixen/BandCamp-uploader