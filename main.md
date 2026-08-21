# musicstuff — Main Plan

**GitHub (latest always):** https://github.com/ezixen/BandCamp-uploader · [releases](https://github.com/ezixen/BandCamp-uploader/releases/latest)

Last updated: 2026-08-20

## Goal

Build a small project to manage music releases and automate distributor uploads. Artist: **ezixen**.

Primary path now: **Bandcamp**, one album at a time. Agent prepares the draft; **user reviews and publishes manually**.  
Later: **DistroKid**. Webpage/management UI comes after the upload flow is reliable.

**Canonical docs for agents (read in this order for an upload job):**

1. This file (`main.md`) — rules + browser startup (enough for a simple AI)
2. [`docs/workflow-guidance.md`](docs/workflow-guidance.md) — step-by-step repetitive upload job
3. [`docs/BANDCAMP_UPLOAD.md`](docs/BANDCAMP_UPLOAD.md) — longer playbook + lessons learned
4. [`AGENTS.md`](AGENTS.md) — project guardrails (venv, approvals, file size)

---

## Current phase

**Phase 1 — Bandcamp upload (in progress)**

- Smooth a repeatable Bandcamp album upload using external Chrome (remote debugging + CDP).
- Agent fills **only** cover, prices, and titles; user reviews and publishes.
- User supplies one local album folder path per run.

**Phase 2 — DistroKid** (blocked until Phase 1 is smooth)

**Phase 3 — Webpage / catalog management** (later)

---

## Bandcamp upload & automated browsing (canonical)

This section is the source of truth for upload behavior. Keep `docs/workflow-guidance.md` and `docs/BANDCAMP_UPLOAD.md` aligned with it.

### What the agent fills (and nothing else)

| Item | Rule |
|---|---|
| **Album cover** | Largest `.jpg` in the album folder (by file size in bytes) |
| **Album price** | `9.99` |
| **Track price** | `0.99` for every uploaded track |
| **Track titles** | **Title only** — see title rules (no artist, no track number, no extension) |
| **Album title** | From the folder name, cleaned the same way (strip `ezixen` if present) |

Do **not** fill description, tags, genre, credits, UPC, release date, about text, or any other fields unless the user explicitly asks in that turn.

### Which files to upload

- Upload **only `.wav` files whose filenames start with a number** (e.g. `01`, `02`, `10`…).
- Sort **numerically by that leading number** (`01` → `02` → … → last).
- Ignore non-wav audio, wavs without a leading number, and other junk in the folder.
- Cover is separate: largest `.jpg` only (not uploaded as a track).

### Title rules

Track title = **only the song title**. Nothing else.

1. Start from the **filename** (not the full path).
2. Remove the file extension (`.wav`, etc.).
3. Remove a leading **track number** if present (`01`, `01.`, `02 -`, `07,`, etc.).
4. Remove artist name **`ezixen`** if present (any side; separators `-`, `_`, `–`, spaces).
5. Replace every **`_`** with **`?`** (filenames use underscore instead of `?`).
6. Trim leftover separators and whitespace.
7. That string is the track title. Do not invent titles.

Example: `01. ezixen - Midnight Drift.wav` → `Midnight Drift`  
Example: `02. ezixen - what's the password, doll_.wav` → `what's the password, doll?`  
(Not `01. Midnight Drift`, not `ezixen - Midnight Drift`.)

Album title (from folder name): strip `ezixen` and clean separators the same way; keep the album name text (including parentheticals like `(swing 4 all)`). Album titles do not apply the `_` → `?` rule unless you ask.

### Publish rule (mandatory)

- After tracks, cover, and prices are set: **Save Album Draft** (not publish) → **stop**.
- **Do not publish** the album.
- Tell the user it is ready for review (include editor URL when available).
- The user reviews in the same graphic Chrome window (fix mistakes if any), then **publishes manually**.
- After they OK / publish, they give the **next folder path**. Do not start another album until then.

### Preferred automation mode

- **Default: graphic external Chrome** on port `9222` (visible window). User can watch and review immediately when the agent reports done.
- Headless / pure CLI CDP is allowed as a fallback if needed, but prefer the visible browser so review + publish can happen right away in that session.
- **No-AI path (same behavior):** run the scripts yourself — see [`scripts/README.md`](scripts/README.md).
  1. `.\scripts\start_bandcamp_chrome.ps1` — then log in
  2. `.\scripts\check_bandcamp_titles.ps1` — optional (prompts for folder path)
  3. `.\scripts\upload_bandcamp_album.ps1` — upload draft (prompts for folder path, or pass it as an argument)

### One-upload-at-a-time

Bandcamp allows only **one track file upload in flight**. Wait until the current `.wav` upload finishes before adding the next.

### UI entry point

1. Open artist dashboard: `https://ezixen.bandcamp.com/dashboard` (must be logged in).
2. Click **`+ Add`** in the top nav → that starts a **new album**.
3. On the new-album page: **read/snapshot the whole page first**, learn where cover, album price, track list, add-track, and track title/price controls are, then proceed.
4. Do not guess blindly; re-snapshot after major UI changes.

---

## Browser startup (required before any upload)

Agents automate Bandcamp through an **external Chrome** with the Chrome DevTools Protocol (CDP), not the daily personal Chrome profile.

### Exact launch (PowerShell)

```powershell
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$userData = "D:\Dev\musicstuff\local-secrets\chrome-debug-profile"
New-Item -ItemType Directory -Force -Path $userData | Out-Null

# If something already owns port 9222 without allow-origins, kill it first, then:
Start-Process -FilePath $chrome -ArgumentList @(
  "--remote-debugging-port=9222",
  "--remote-allow-origins=http://127.0.0.1",
  "--user-data-dir=$userData",
  "https://bandcamp.com/login"
)
```

| Parameter | Why |
|---|---|
| `--remote-debugging-port=9222` | CDP endpoint at `http://127.0.0.1:9222` |
| `--remote-allow-origins=http://127.0.0.1` | Without an allowed origin, WebSocket clients get **403 Forbidden**. Do not use `*` — any page in that Chrome could then attach to CDP. CDP clients must send `Origin: http://127.0.0.1` |
| `--user-data-dir=...\local-secrets\chrome-debug-profile` | Isolated profile (gitignored); keeps cookies/login without touching normal Chrome |
| Start URL | Login or dashboard |

### Verify CDP is alive

```powershell
(Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing).Content
```

Optional Python smoke (shared venv):

```powershell
C:/.venv/Scripts/python.exe -c "import json,urllib.request,websocket; pages=json.load(urllib.request.urlopen('http://127.0.0.1:9222/json/list')); page=next(p for p in pages if p.get('type')=='page'); ws=websocket.create_connection(page['webSocketDebuggerUrl'], suppress_origin=True, header=['Origin: http://127.0.0.1']); ws.send(json.dumps({'id':1,'method':'Runtime.evaluate','params':{'expression':'document.title','returnByValue':True}})); print(ws.recv()); ws.close()"
```

### Startup sequence before filling titles

1. Launch Chrome with the parameters above (or confirm `9222` already works with allow-origins).
2. **User logs into Bandcamp** in that window (agent does not enter passwords).
3. Confirm dashboard: `https://ezixen.bandcamp.com/dashboard` shows artist **ezixen**.
4. User gives **one album folder path** on the PC.
5. Agent lists folder: numbered `.wav` files in order + largest `.jpg`.
6. Click **`+ Add`**, snapshot the editor page, map controls.
7. Only then: cover → album price → tracks one-by-one (title + track price) → stop for review.

### Driving the browser

- Prefer CDP against `127.0.0.1:9222` (Chrome DevTools MCP if attached to that browser, or Python `websocket` + CDP).
- Cursor’s internal browser is **not** the login session; use the external debug Chrome for Bandcamp.
- After each click/upload, wait and take a fresh snapshot before the next action.

---

## Per-album job (short)

1. Startup sequence complete + folder path known.
2. `+ Add` → new album page → get bearings.
3. Set album title (from folder name), album price `9.99`, upload largest `.jpg`.
4. For each numbered `.wav` in order: upload → wait done → set title → set `0.99` → next.
5. Recheck cover / prices / titles / order.
6. Message user: draft ready; **do not publish**.
7. Wait. User reviews and publishes manually.
8. Note any friction in `docs/BANDCAMP_UPLOAD.md` → Lessons.

---

## Agent rules (project-wide)

- Canonical ops contract: [`AGENTS.md`](AGENTS.md)
- Python: always `C:/.venv/Scripts/python.exe` (no project-local venv)
- Verification: prefer scripts + logging under `artifacts/test_cache/` when the helper exists; always report what ran and the result
- Never claim “album done” without completing the draft fields above and telling the user to review
- DistroKid: do not start until Bandcamp flow is smooth

---

## Open items

- [ ] Confirm album source folder path(s) for releases
- [ ] Complete first Bandcamp test album with user review (no publish by agent)
- [ ] Port or add `scripts/testing/update_test_cache.py` when Python tests exist
- [ ] DistroKid playbook (after Bandcamp is smooth)
- [ ] Webpage scope once distribution workflow is stable

## Status

| Area | Status |
|---|---|
| AGENTS.md adapted from WIWM (generic) | done |
| main.md upload + browser startup | done |
| workflow-guidance.md | done |
| Bandcamp playbook | aligned / refining via test runs |
| External Chrome debug (`9222` + allow-origins) | documented + working |
| Bandcamp login (ezixen) | ready when debug Chrome session is up |
| First test album: Glorious Passion (swing 4 all) | draft ready for user review (not published) |
| Script test: this moonlit operation | draft ready — `edit_album?id=1992289722` |
| DistroKid | not started |
| Webpage | not started |
