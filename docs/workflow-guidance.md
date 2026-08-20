# Bandcamp album upload — workflow guidance

**GitHub (latest always):** https://github.com/ezixen/BandCamp-uploader · [releases](https://github.com/ezixen/BandCamp-uploader/releases/latest)

Simple, repetitive job for any AI agent.

**User gives:** a folder path on the PC.  
**Agent does:** start/attach debug Chrome if needed → open new album → upload numbered `.wav` files in order → set cover + prices + titles → **stop for human review (do not publish)**.

Full rules and browser parameters: [`../main.md`](../main.md)  
Longer playbook / lessons: [`BANDCAMP_UPLOAD.md`](BANDCAMP_UPLOAD.md)

Artist: **ezixen** · Dashboard: `https://ezixen.bandcamp.com/dashboard`

---

## 0. Before you touch Bandcamp

### A. Start the right browser (if not already up)

```powershell
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$userData = "D:\Dev\musicstuff\local-secrets\chrome-debug-profile"
New-Item -ItemType Directory -Force -Path $userData | Out-Null
Start-Process -FilePath $chrome -ArgumentList @(
  "--remote-debugging-port=9222",
  "--remote-allow-origins=*",
  "--user-data-dir=$userData",
  "https://bandcamp.com/login"
)
```

All three flags matter:

- `--remote-debugging-port=9222`
- `--remote-allow-origins=*` (required or CDP gets 403)
- `--user-data-dir=D:\Dev\musicstuff\local-secrets\chrome-debug-profile`

Check: `http://127.0.0.1:9222/json/version` returns JSON.

### B. Human login

Ask the user to log into Bandcamp in **that** Chrome window. Do not enter passwords.

Confirm you can open `https://ezixen.bandcamp.com/dashboard` and see **ezixen**.

### C. Folder path

User must give the album folder path. Until then, do not click `+ Add`.

---

## 1. Prepare file list from the folder

From the given folder only:

1. Collect `.wav` files whose **filename starts with a number** (`01…`, `2…`, `10…`, etc.).
2. Sort by that leading number ascending.
3. Pick the **largest `.jpg`** by file size → album cover.
4. Ignore everything else (other audio, unnumbered wavs, txt, etc.).

Derive:

- **Album title** = folder name, strip `ezixen` / clean separators (keep album name text).
- **Each track title** = **title only** from the wav filename: strip extension, leading track number, and `ezixen`; replace `_` with `?`. No numbers, no artist, no extension in the Bandcamp title field.

You will set:

- album price **9.99**
- each track price **0.99**

You will **not** fill any other form fields.

---

## 2. Open new album and get bearings

1. Go to dashboard.
2. Click **`+ Add`** (top nav) → new album editor.
3. **Read the whole page** (snapshot). Note where these controls are:
   - album title
   - album artwork / cover upload
   - album price
   - add / upload track
   - per-track title
   - per-track price
   - publish / save (you will **not** publish)
4. Only after you know the layout, fill fields.

---

## 3. Fill album-level fields

1. Album title (from folder name).
2. Album price → `9.99`.
3. Upload cover → largest `.jpg` from the folder.

Stop if cover upload fails; report and wait.

---

## 4. Add tracks (one at a time)

For each numbered `.wav` in order:

1. Start add/upload for **one** file.
2. **Wait until that upload fully finishes** (Bandcamp only allows one at a time).
3. Set track title (from filename rules).
4. Set track price → `0.99`.
5. Confirm order still matches `01`, `02`, …
6. Then next file.

If stuck: stop, describe what you see, wait for the user. Do not hammer retries.

---

## 5. Done signal (no publish)

Checklist:

- [ ] Largest jpg used as cover
- [ ] Album price 9.99
- [ ] Every numbered wav uploaded once, in order
- [ ] Every track titled correctly
- [ ] Every track price 0.99
- [ ] No extra fields filled
- [ ] **Save Album Draft** clicked (or equivalent)
- [ ] **Publish was not clicked**

Then message the user, for example:

> Album draft ready for review. Editor: `<url>`. Cover: `<filename>`. Tracks: `N`. Prices: album 9.99 / tracks 0.99. **Not published** — please review in the debug Chrome window and publish when happy. Send the next folder when ready.

**Mode:** Prefer the **visible** debug Chrome window (not headless) so the user can review and publish immediately after your report.

Wait for the next folder path. Do not start another album until they send one.

---

## Quick don’ts

- Don’t publish.
- Don’t upload non-wav or unnumbered wavs.
- Don’t fill tags, description, credits, dates, etc.
- Don’t start the next track upload before the current one finishes.
- Don’t use a random Chrome window — only the debug profile on port **9222**.
