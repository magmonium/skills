---
name: to-tasks
description: Pick next PRD from prd/draft/, break it into at most four typed task files (frontend, backend, integration, migration) under tasks/draft/ — plus optional one-ui reusable-component task if user approves — then move the PRD to prd/in-progress/ once fully divided. Use when user wants to convert a PRD draft into task files, says "to tasks", or asks to break the next PRD into tasks.
---

# To Tasks

Pick next PRD from `prd/draft/` → write task files to `tasks/draft/` → when PRD FULLY divided into tasks, move it to `prd/in-progress/`.

## Process

### 1. Pick PRD

- Argument given (index or path) → use that PRD.
- No argument → lowest `NNNN_` prefix in `prd/draft/` (oldest waits longest).
- Folder empty or missing → tell user, stop.

Read PRD fully. Check `docs/adr/` (or project ADR folder) for decisions touching same area — tasks must respect them.

### 2. Explore codebase

Find: existing reusable components (One UI library first), theme, API patterns, i18n setup, model conventions. Task descriptions must use real project vocabulary, not invented names.

### 3. Slice into tasks — MAX FOUR per PRD

Fixed task set. Create each ONLY when PRD needs it (pure-backend PRD → no frontend/integration task; etc.):

| # | Type | Job |
|---|------|-----|
| 1 | `frontend` | Pure FE. Screen/UI with MOCK data — zero API calls. Use One UI components + One UI knowledge to make screen beautiful. SAME task handles assets (icons, images, illustrations) AND translations — body must instruct agent to run `/translate` skill after UI built. Code compiles, lint passes. |
| 2 | `backend` | API endpoints, business logic, DB changes. Defines contract (request/response shapes) frontend will later bind to. Runs PARALLEL with frontend — frontend mocked, no dependency between them. |
| 3 | `integration` | Swap frontend mocks for real backend API. Wire end-to-end: loading/error states, real data in, mocks out, feature actually works. Depends on frontend + backend. |
| 4 | `migration` | Stabilization pass over WHOLE implementation. Hunt deviations: code architecture (FSD layering, module boundaries), DRY violations, security issues; run `/fe-review` skill on FE delta. Fix/migrate what found — code stable + beautiful. OPTIONAL — skip when implementation small/clean. Depends on integration. |

One UI reusable-component check — do DURING slicing, before writing files:

- Shaping frontend task → scan PRD UI for pieces reusable beyond this feature (generic card, picker, status badge…).
- Candidate found → ASK USER: "X looks reusable — create One UI component task for it?"
- Yes → add `one-ui` task: build component in One UI library; frontend task depends on it.
- `one-ui` task is PURELY presentational — UI/UX + aesthetics ONLY. Zero business logic: no API calls, no state management, no domain rules, no feature-specific behavior. Component takes data via inputs, emits events via outputs — consumer (frontend task) owns all logic. Task body must state this constraint.
- No → frontend task builds it locally inside the app.

Rules:

- Full coverage: every PRD user story / decision lands in some task. Nothing left unassigned.
- Each task lists what blocks it. Sequence number = dependency order.
- Task needing human (design review, credentials, store approval, manual QA) → mark `Human:` with what human must do. Prefer no-human tasks.
- Every task refs main PRD + any ADR it leans on.

UI rules (frontend + one-ui tasks must state them):

- Minimal HTML/CSS — reuse One UI / app components before writing new markup.
- New UI → small reusable components, not one big blob.
- Logic out of templates — functions separate, components thin.
- Follow FSD (Feature-Sliced Design) layering of the app.

Order: one-ui (if any) → frontend ∥ backend → integration → migration (if any).

### 4. Write task files

Numbering: `NNNN_SS_<type>_<kebab-desc>.md` in `tasks/draft/` — NNNN = PRD index, SS = 2-digit sequence in dependency order. Create folder if missing.

Format per task: see [TASK-FORMAT.md](./TASK-FORMAT.md). Prose caveman: drop articles/filler/hedging, fragments OK, technical terms exact.

### 5. Move PRD — only when fully divided

Gate: ALL tasks written, full PRD coverage verified (step 3 rule). Partial breakdown → PRD STAYS in `prd/draft/`, tell user what remains.

When gate passes: move `prd/draft/NNNN_<slug>.md` → `prd/in-progress/NNNN_<slug>.md` (create folder if missing; `git mv` when repo tracks it). Task `Refs:` lines point at in-progress path.

### 6. Report

Reply with: PRD moved (old → new path), then one line per task — filename, type, mode, human flag, depends. Note migration task skipped + why, when skipped.
