# Bandcamp scripts (no AI)

Drive a visible Chrome via CDP on port **9222**. Three steps:

| Step | Script | What it does |
|---|---|---|
| 1 | `start_bandcamp_chrome.ps1` | Start debug Chrome; you log in |
| 2 | `check_bandcamp_titles.ps1` | Optional: preview titles/cover (no upload) |
| 3 | `upload_bandcamp_album.ps1` | Upload album draft (no publish) |

Prefer **pwsh** if you have it.

## Typical session

```powershell
cd D:\Dev\musicstuff

# 1) Chrome + login (once per session)
.\scripts\start_bandcamp_chrome.ps1

# 2) Optional title check — prompts for path, or pass it:
.\scripts\check_bandcamp_titles.ps1
.\scripts\check_bandcamp_titles.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"

# 3) Upload draft — prompts for path, or pass it:
.\scripts\upload_bandcamp_album.ps1
.\scripts\upload_bandcamp_album.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"
```

When prompted, paste a path like:

```text
d:\music\ezixen\2026\ezixen - goasted (louder)
```

Quotes around the path are optional; the scripts strip them.

## What the upload does

- Album title from folder name (strips `ezixen`)
- Cover = largest `.jpg`
- Album price `9.99`
- Numbered `.wav` files only, in order, one at a time
- Track title = title only (no number, no artist, no extension; `_` → `?`)
- Track price `0.99`
- **Save Album Draft** — does not publish

Then review in Chrome and publish yourself.

Underlying Python: `scripts/bandcamp_upload_album.py` via `C:/.venv/Scripts/python.exe` (needs `websocket-client`).
