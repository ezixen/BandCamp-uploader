# Bandcamp Uploader

Upload one local album folder to Bandcamp as a **draft**. You review and publish yourself.

Automation uses a **visible Chrome** window (Chrome DevTools Protocol on port 9222) plus small PowerShell scripts. No Bandcamp password is stored in this repo.

| | |
|---|---|
| Humans (short) | [`how2use.txt`](how2use.txt) |
| Install | [`install.ps1`](install.ps1) (elevated; winget Python + pip) |
| Prices | [`prices.txt`](prices.txt) — edit anytime |

---

## What it does

For each album folder you point at, the uploader:

1. Opens Bandcamp’s **new album** editor in your debug Chrome session  
2. Sets **album title** (from the folder name)  
3. Sets **album price** from `prices.txt`  
4. Uploads the **largest `.jpg` / `.jpeg`** in the folder as cover  
5. Uploads each numbered **`.wav`** one at a time (Bandcamp allows only one upload at a time)  
6. Sets each **track title** and **track price** (from `prices.txt`)  
7. Clicks **Save Album Draft** — never Publish  

---

## First-time setup

### Requirements

- Windows 10/11  
- [Google Chrome](https://www.google.com/chrome/)  
- `winget` (App Installer from Microsoft Store — usually already present)  
- Ability to approve a **UAC / Administrator** prompt once for install  

### Install (automated)

In PowerShell (`pwsh` preferred), from the project folder:

```powershell
cd path\to\BandCamp-uploader
.\install.ps1
```

Approve the elevation prompt. The script will:

1. Re-launch itself as Administrator  
2. `winget install` **Python 3.13** (default install location; change the id in `install.ps1` if you prefer another version)  
3. `pip install -r requirements.txt` (`websocket-client`)  
4. Ensure `prices.txt` exists  

To verify elevation reaches winget **without** installing:

```powershell
.\install.ps1 -DryRun
```

After a real install, open a **new** terminal so PATH picks up Python.

### Log into Bandcamp once (local Chrome profile)

```powershell
.\scripts\start_bandcamp_chrome.ps1
```

- Starts Chrome with `--remote-debugging-port=9222` and `--remote-allow-origins=*`  
- Uses an isolated profile: `local-secrets\chrome-debug-profile` (gitignored)  
- Log into Bandcamp in that window  

Your login cookies stay **only on your PC** in that profile folder. They are not part of the git repo and are not sent to GitHub. Log in again only if you delete that folder or the session expires.

---

## Every upload

```powershell
# 1) Debug Chrome (skip if already running + logged in)
.\scripts\start_bandcamp_chrome.ps1

# 2) Optional title / price preview
.\scripts\check_bandcamp_titles.ps1
.\scripts\check_bandcamp_titles.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"

# 3) Upload draft
.\scripts\upload_bandcamp_album.ps1
.\scripts\upload_bandcamp_album.ps1 "d:\music\ezixen\2026\ezixen - goasted (louder)"
```

If you omit the path, the script prompts you to paste it. Quotes are optional.

Then review the draft in Chrome and publish manually.

---

## File naming (important)

Track files must start with a **number**, then **artist**, then ` - `, then **title**:

```text
01. ezixen - intro.wav
02. ezixen - what's the password, doll_.wav
```

| Part | Example | Used for |
|---|---|---|
| Number | `01.` | Sort order (only these wavs are uploaded) |
| Artist | `ezixen` | Stripped from the Bandcamp title |
| Separator | ` - ` | Required |
| Title | `intro` | Becomes the Bandcamp track title |
| Extension | `.wav` | Required (mp3 etc. ignored) |

Title rules applied by the script:

- Drop number + artist  
- Keep only the track title  
- Replace `_` with `?` (so `doll_` → `doll?`)  

Album folder name example: `ezixen - goasted (louder)` → album title `goasted (louder)`.

---

## Cover art

Among all `.jpg` / `.jpeg` files in the album folder, the script picks the **largest by file size**.

---

## Prices (`prices.txt`)

Edit this file in the project root whenever you want. Scripts read it **on every run**.

```text
album=9.99
track=0.99
```

No code changes needed — save the file and upload.

---

## Project layout

```text
install.ps1                 Elevated setup (winget Python + pip)
how2use.txt                 Short human steps
README.md                   This file
prices.txt                  Album / track prices
requirements.txt            Python deps
scripts/
  common.ps1                Shared path helpers (find Python on PATH)
  start_bandcamp_chrome.ps1 Debug Chrome launcher
  check_bandcamp_titles.ps1 Dry-run preview
  upload_bandcamp_album.ps1 Draft upload
  bandcamp_upload_album.py  CDP automation
local-secrets/              Local Chrome profile (not in git)
```

Python is resolved dynamically (`PATH`, `py -3`, common install dirs). No hard-coded `C:\.venv` required (that path is only a fallback if present).

---

## Safety

- Does **not** publish  
- Does **not** store Bandcamp passwords in the repo  
- Fills only title, cover, and prices (not tags, description, credits, etc.)  
- Respect [Bandcamp’s terms](https://bandcamp.com/terms_of_use)  

---

## Troubleshooting

| Problem | Fix |
|---|---|
| UAC / elevation cancelled | Re-run `.\install.ps1` and accept the prompt |
| `winget` missing | Install “App Installer” from Microsoft Store |
| `Python not found` | Finish install, then open a **new** terminal |
| `Chrome CDP not on 9222` | Run `start_bandcamp_chrome.ps1` |
| CDP WebSocket **403** | Chrome must use `--remote-allow-origins=*` (start script does this). Kill old debug Chrome and restart. |
| Login wall on editor | Log in again in the debug Chrome window |
| Wrong cover | Check which jpg/jpeg is largest in the folder |
| Wrong prices | Edit `prices.txt` and re-upload / fix in Bandcamp UI |

---

## License / use

Personal automation for your own Bandcamp artist account.
