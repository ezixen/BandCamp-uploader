# Bandcamp Uploader

Upload one album folder to Bandcamp as a **draft** (you review and publish yourself).

A small Python script drives a **visible Chrome** window through the Chrome DevTools Protocol (CDP). PowerShell wrappers make the steps easy to run by hand.

Artist defaults (edit in `scripts/bandcamp_upload_album.py` if needed):

| Field | Value |
|---|---|
| Album price | `9.99` |
| Track price | `0.99` each |
| Cover | Largest `.jpg` / `.jpeg` in the folder |
| Audio | Only `.wav` files whose names **start with a number**, in numeric order |
| Track title | Title only — no track number, no artist name (`ezixen`), no extension; `_` → `?` |
| Publish | **Never** — only **Save Album Draft** |

---

## Requirements

- Windows
- [Google Chrome](https://www.google.com/chrome/)
- [PowerShell 7+](https://github.com/PowerShell/PowerShell) recommended (`pwsh`); Windows PowerShell 5.1 usually works too
- Python in the shared venv: `C:/.venv\Scripts\python.exe`
- Python package: `websocket-client`  
  ```powershell
  C:/.venv/Scripts/python.exe -m pip install websocket-client
  ```

---

## First-time setup (do this once)

### 1. Get the files

Clone or copy this project to a folder you can write to, e.g. `D:\Dev\musicstuff`.

### 2. Install the Python dependency

```powershell
C:/.venv/Scripts/python.exe -m pip install websocket-client
```

If you use another venv, change the `python` path inside the `.ps1` scripts.

### 3. Start the debug Chrome profile and log in

```powershell
cd D:\Dev\musicstuff
.\scripts\start_bandcamp_chrome.ps1
```

What this does:

- Opens Chrome with remote debugging on port **9222**
- Uses an **isolated profile** under `local-secrets\chrome-debug-profile` (not your everyday Chrome)
- That profile is **gitignored** — login cookies stay on your PC only

In the window that opens:

1. Log into [Bandcamp](https://bandcamp.com/login) as your artist account.
2. Confirm you can open your artist dashboard.
3. Leave this Chrome alone for uploads (or reopen later with the same script — it should still be logged in).

You only need to log in again if you clear that profile folder, use a different PC, or Bandcamp expires the session.

### 4. You’re set

Next times you only need steps under **Every upload** below (Chrome may already be running and logged in).

---

## Every upload

Open a terminal in the project folder (`pwsh` preferred):

```powershell
cd D:\Dev\musicstuff
```

### Step 1 — Start debug Chrome (if not already up)

```powershell
.\scripts\start_bandcamp_chrome.ps1
```

If Chrome is already on port 9222, the script reuses it. Make sure you’re still logged into Bandcamp in that window.

### Step 2 — Optional: check titles before uploading

```powershell
.\scripts\check_bandcamp_titles.ps1
```

When prompted, paste your album folder path, for example:

```text
d:\music\ezixen\2026\ezixen - goasted (louder)
```

Or pass the path as an argument:

```powershell
.\scripts\check_bandcamp_titles.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"
```

This only prints album title, cover file, and each track title. It does **not** upload.

### Step 3 — Upload draft

```powershell
.\scripts\upload_bandcamp_album.ps1
```

Paste the same folder path when asked, or:

```powershell
.\scripts\upload_bandcamp_album.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"
```

The script will:

1. Open Bandcamp’s **new album** editor in the debug Chrome
2. Set album title and price `9.99`
3. Upload the largest jpg as cover
4. Upload each numbered `.wav` **one at a time** (Bandcamp only allows one at a time)
5. Set each track title and price `0.99`
6. Click **Save Album Draft**
7. Print a summary URL

Then **you** review in Chrome and publish if it looks right.

---

## Album folder layout

Example:

```text
ezixen - my album name\
  01. ezixen - first song.wav
  02. ezixen - second song_.wav    ← _ becomes ? in the title
  07, ezixen - odd separator.wav   ← leading number+comma is OK
  ezixen - my album name.jpg       ← used if it is the largest jpg
  something-else.mp3               ← ignored
```

- Non-wav audio is ignored.
- Wavs that do **not** start with a digit are ignored.
- Several jpgs: the **largest by file size** is the cover.

---

## Scripts (what each file is)

| File | Role |
|---|---|
| `scripts/start_bandcamp_chrome.ps1` | Start / reuse debug Chrome |
| `scripts/check_bandcamp_titles.ps1` | Dry-run title preview |
| `scripts/upload_bandcamp_album.ps1` | Full draft upload |
| `scripts/bandcamp_upload_album.py` | Actual CDP automation |

---

## Safety notes

- Does **not** publish. You publish manually after review.
- Does **not** put Bandcamp passwords in the repo. Login lives only in the local Chrome debug profile.
- `local-secrets/` must stay out of git (see `.gitignore`).
- Only fills title, cover, and prices — not tags, description, credits, etc.

---

## Troubleshooting

| Problem | What to try |
|---|---|
| `Chrome CDP not on 9222` | Run `start_bandcamp_chrome.ps1` again |
| CDP / WebSocket **403** | Chrome must be started with `--remote-allow-origins=*` (the start script does this). Kill old Chrome on 9222 and restart with the script. |
| Album editor missing / login wall | Log in again in the debug Chrome window |
| Wrong cover | Check which `.jpg` is largest in the folder |
| Upload stuck | Bandcamp allows one track at a time; wait. Re-run only after checking you don’t already have a partial draft open. |

---

## License / use

For personal automation of your own Bandcamp artist account. Respect [Bandcamp’s terms](https://bandcamp.com/terms_of_use).
