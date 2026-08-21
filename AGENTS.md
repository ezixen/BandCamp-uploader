# musicstuff — Agent Instructions

**GitHub (latest always):** https://github.com/ezixen/BandCamp-uploader · [releases](https://github.com/ezixen/BandCamp-uploader/releases/latest)

Root operational guardrail contract for AI agents and human contributors.
Canonical source: `AGENTS.md`. Copilot mirror (when present): `.github/copilot-instructions.md`.

Product: **musicstuff** — webpage and tooling to manage, prepare, and distribute music releases (Bandcamp first; DistroKid later).

---

## 1. Project Overview & Environments

| Stage | Purpose | Notes |
|---|---|---|
| **Local** | Day-to-day development & upload automation | Scripts + browser automation against live distributor UIs |
| **Dev** | Shared integration / smoke | TBD when hosting exists |
| **Staging** | Pre-prod gate | TBD when hosting exists |
| **Production** | Live site / published catalog | TBD when hosting exists |

- **Python venv**: `C:/.venv/Scripts/python.exe` (**always** use `C:/.venv` — do not create a project-local venv)
- **Path convention**: Use repository-relative paths (`docs/`, `Plan/`, `scripts/`, `web/` when present). Shared templates (if any) live at `<parent-of-repo>/templates/`.
- **Secrets**: Local credentials under `local-secrets/` (gitignored). Also check `D:\Dev\Save\secrets` when needed — never commit secrets.

Fill environment IDs and live URLs into this table when infra is provisioned. Until then, use placeholders in docs (`<hosting-url>`, `<api-url>`).

---

## 2. Approvals & Guardrails (MUST ASK FIRST)

Stop and get **explicit user approval in the same turn** before running commands for:

1. **Instructions & Config**: Modifying `AGENTS.md`, `.github/copilot-instructions.md`, hosting config, or CI deploy workflows.
2. **Auth & Database**: Altering auth flows, session rules, database schemas, migrations, or security rules.
3. **Cloud Cost & Hosting**:
   - Deploys / rollbacks / clones
   - Managed DB always-on policies, tier changes, start/stop
   - Secret Manager writes or IAM mutations
4. **Deployments**: Dev / staging / prod deploys (including `gh workflow run`).
5. **Data Loss**: Removing or overwriting user data, broad file deletions.
6. **Distributor publishing**: Final publish / go-live on Bandcamp, DistroKid, or similar without human review of the filled form.

*Rule Violations:* If a rule prevents fulfilling a request, explicitly cite the rule to the user instead of bypassing it.

---

## 3. Deployment & Promotion Workflow

Canonical runbook (create when infra exists): `docs/DEPLOYMENT_PROMOTION_RUNBOOK.md`

- **Build Once, Promote Staged**: Build artifacts once from **`dev`**, then promote: `local` → shared `dev` → `staging` → **STOP**.
- **Mandatory Staging Gate**: Test online in staging, report results, and await explicit human OK before **production** (`main`). Never promote shared-dev directly to production in one uninterrupted step.
- **Post-Deploy Verification**: Hard-refresh browser tabs after deployment. Prefer a scripted smoke when available.

---

## 4. Security & Data Protection

- **Secrets**: Never commit secrets, tokens, private keys, credential JSONs, or DB files. Use placeholders (`<api-key>`, `<token>`) in docs. Keep local credentials under `local-secrets/` (gitignored).
- **Auth & Billing Boundaries**: Functional endpoints must enforce auth, scope, rate limits, and (when monetization ships) quota/billing.
- **Provider Keys**: Third-party keys are request-scoped when needed; never store them server-side unless the product explicitly requires it and the user approved storage design.
- **SQL Safety**: Parameterize all queries via ORM/expression APIs. Never build SQL with string concatenation, f-strings, or manual escaping. Keep DB error messages generic to clients.
- **Distributor accounts**: Do not store Bandcamp/DistroKid passwords in the repo. Prefer interactive login in the external debug browser; session stays in that Chrome profile.

---

## 5. Development & UI Conventions

- **Terminal / Shell (Windows)**:
  - Prefer **`pwsh`** (PowerShell 7+) over Windows PowerShell 5.1 (`powershell.exe`) whenever it is installed and the task benefits (modern syntax, better UTF-8, `&&`-style pipelines, cross-platform cmdlets, fewer legacy quirks).
  - Invoke explicitly when spawning scripts: `pwsh -NoProfile -File ...` rather than relying on the default host if that host is Windows PowerShell.
  - Use an **elevated** (Administrator) prompt when the task needs it and elevation would yield better/correct results — e.g. binding privileged ports, installing system-wide tools, writing under `C:\Program Files`, killing processes owned by elevation, or CDP/Chrome launches that fail without admin. Ask the user to approve elevation if it is not already available; do not assume silent UAC bypass.
  - Prefer non-elevated shells for day-to-day work (uploads, git, Python under `C:/.venv`) unless elevation is actually required.
- **Terminal Hygiene**: Prefer dedicated start/stop scripts when present. Log stopped PIDs/ports. Avoid leaving orphaned long-running processes.
- **Branches**: Default working branch is **`dev`**. **`main`** is production-only. Promote `dev` → staging gate → `main` only after explicit approval.
- **Browser Automation**:
  - Default smoke / page checks: Cursor browser tools when sufficient.
  - Logins, OAuth, and distributor upload UIs (Bandcamp, DistroKid): use **external** Chrome with remote debugging (`http://127.0.0.1:9222`).
  - Human logs in once; agent continues in the same debug session.
- **Product UI Rules** (when a webpage exists):
  - **Time**: Under 60s → seconds only (`45s`). 60s+ → minutes + seconds (`2m 15s`). Never display milliseconds.
  - **Dates**: Always `dd/mm/yyyy` with timezone offset shown where relevant.
  - **Timeouts**: Max default timeout cap is `600,000 ms` (10 minutes).
  - **Errors/Status**: Render inside the relevant section, near submit buttons — not only as global toasts.
  - **Installs (Windows)**: x64 → `C:\Program Files`, x86 → `C:\Program Files (x86)`.

### 5.1 File size & modularity (MANDATORY)

Keep source **short, one concern per file**, and composed by imports. Do **not** grow megapage / megamodule files.

| Limit | Lines (editor line count) | Rule |
|---|---|---|
| **Target** | **≤ 400** | Preferred max for new or edited implementation files |
| **Soft** | **401–600** | Allowed only temporarily; **split before the next feature** touches that file |
| **Hard** | **> 600** | **Do not add logic.** Split first, then implement. Never leave a hand-written source file above **800** lines |

**Rules of thumb:**

1. **One primary responsibility per file**.
2. **Extract before extend**: if the file you need to edit is already **> 600** lines, split it in the same change set **before** adding the feature.
3. **New feature = new file(s)** when it would push a file past **400**, unless it is a 1–5 line fix in place.
4. **Do not** merge small files into a “god file” for convenience.
5. **Excluded from limits**: generated code, lockfiles, vendored third_party, large static assets.
6. **Tests**: one focused test module per concern; avoid 1000+ line test files — split by feature.

**Agent checklist before “done”:** report any edited implementation file still **> 600** lines and either split it or explicitly mark it blocked pending split.

---

## 6. Language

- Project docs and agent communication: **English**.
- Track/album metadata on distributors: use titles as derived from filenames (see `docs/BANDCAMP_UPLOAD.md`); do not invent alternate languages unless the user asks.

---

## 7. Testing & Verification

- **Python**: Always invoke via `C:/.venv/Scripts/python.exe`.
- **Logging / script verification**: Prefer running Python scripts through the source-aware cache helper so results are logged under `artifacts/test_cache/` (including `source_test_results.json`) when the helper exists:
  ```powershell
  C:/.venv/Scripts/python.exe -m compileall .
  C:/.venv/Scripts/python.exe scripts/testing/update_test_cache.py --suite-name "<suite-name>" -- C:/.venv/Scripts/python.exe -m pytest tests -q
  ```
  Until that helper is ported here, still run scripts with `C:/.venv/Scripts/python.exe` and record stdout/stderr outcomes in the reply (what ran + observed result).
- **Never claim “done”** without stating what was run and the observed result.
- **Upload runs**: After filling an album on Bandcamp, stop and ask the user to review before treating the album as complete.

---

## 8. Documentation & Plan Discipline

- **Docs Layout**: Living docs in `docs/`. Implementation plans in `Plan/`. Main project plan: `main.md`.
- **Repeated distributor workflows**: Keep playbooks under `docs/` (e.g. `docs/BANDCAMP_UPLOAD.md`). Update them when the process is smoothed.
- **Plan Tracking**: After substantial work, update the active plan file and `Plan/ExecutionStatus.plan` when present. Statuses: `ready`, `in progress`, `blocked`, `done-tested-working`.
- **Git Hygiene**: Check `git status --short --branch`. Day-to-day commits go on **`dev`** (default). **`main`** is production-only after staging OK + explicit promote approval.

---

## 9. Default Agent Workflow

1. Read this file (especially **§5.1 file size**), `main.md`, and the relevant playbook under `docs/`.
2. Prefer smallest vertical slice that ships a testable step (one album upload path, one page feature).
3. TDD where practical: failing test → implement → pass → commit (when user asks for commits).
4. If a target file is **> 600** lines, **split first** (§5.1), then implement.
5. Update plan status when finishing a chunk of work.
6. Ask before anything in §2.

---

## 10. Distributor upload (summary)

Canonical rules + browser startup: **`main.md`**.  
Simple repetitive checklist: **`docs/workflow-guidance.md`**.  
Longer playbook: **`docs/BANDCAMP_UPLOAD.md`**.

High level:

1. Start/attach external Chrome on `9222` with `--remote-allow-origins=http://127.0.0.1` and the project debug profile; user logs in. CDP clients must send `Origin: http://127.0.0.1` (never use `*`).
2. One album folder path from the user.
3. `+ Add` → new album; snapshot page and learn the layout first.
4. Fill **only** album title, largest `.jpg` cover, album price `9.99`, numbered `.wav` tracks (**title-only** names + `0.99`). Nothing else.
5. Upload numbered wavs one at a time, in numeric order; wait between uploads.
6. **Do not publish** — tell the user the draft is ready; they publish manually.
7. Multiple uploader processes may share one debug Chrome: each opens and keeps its **own** tab(s). See sibling DistroKid-uploader / DK-BC-Uploader repos.
