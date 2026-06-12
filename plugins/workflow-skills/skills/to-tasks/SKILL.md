---
name: to-tasks
description: Pick next PRD from prd/draft/, break it into small caveman-style task files under tasks/draft/, then move the PRD to prd/in-progress/ once fully divided. Tasks are typed (modelling, backend, frontend, migration, integration, assets, translation), sequenced by dependency, and sized so an agent can complete each one alone. Use when user wants to convert a PRD draft into task files, says "to tasks", or asks to break the next PRD into tasks.
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

Find: existing reusable components, theme, API patterns, i18n setup, model conventions. Task descriptions must use real project vocabulary, not invented names.

### 3. Slice into tasks

Rules:

- Each task SMALL + INDEPENDENT — one agent, one sitting, no ambiguity.
- Many small tasks beat few big ones. Multiple tasks of same type fine.
- Full coverage: every PRD user story / decision lands in some task. Nothing left unassigned.
- Each task lists what blocks it. Sequence number = dependency order.
- Task needing human (design review, credentials, store approval, manual QA) → mark `Human:` with what human must do. Prefer no-human tasks.
- Some tasks implement; some exist as reference for other tasks (e.g. modelling) → mark `Mode: reference`.
- Every task refs main PRD + any ADR it leans on.

Type vocabulary + what each does:

| Type | Job |
|------|-----|
| `modelling` | Define data types/shapes shared by FE+BE. Swagger/interface generated from this. Often `Mode: reference` — other tasks read it. Usually first. |
| `backend` | API endpoints, business logic, DB per modelling contract. |
| `frontend` | NEW screen/UI with MOCK data. Follow existing app theme. Make beautiful. No API calls. |
| `migration` | Change to EXISTING screen/component. Same UI rules as frontend, mock data. |
| `integration` | Bind frontend to real API. Real data in, mocks out. |
| `assets` | Create frontend assets (icons, images, illustrations). |
| `translation` | Create i18n keys + asset files for new UI strings. Task body must instruct agent to run `/translate` skill — it discovers raw text + missing keys, creates en-only YAMLs, runs `npm run translate:fix`, verifies + lints. |

New screen → `frontend`. Existing screen changed → `migration`.

UI rules (frontend + migration tasks must state them):

- Minimal HTML/CSS — reuse app components before writing new markup.
- New UI → small reusable components, not one big blob.
- Logic out of templates — functions separate, components thin.
- Follow FSD (Feature-Sliced Design) layering of the app.

Typical order: modelling → backend ∥ assets ∥ frontend/migration(mock) → translation → integration. Frontend parallel with backend because mocked.

### 4. Write task files

Numbering: `NNNN_SS_<type>_<kebab-desc>.md` in `tasks/draft/` — NNNN = PRD index, SS = 2-digit sequence in dependency order. Create folder if missing.

Format per task: see [TASK-FORMAT.md](./TASK-FORMAT.md). Prose caveman: drop articles/filler/hedging, fragments OK, technical terms exact.

### 5. Move PRD — only when fully divided

Gate: ALL tasks written, full PRD coverage verified (step 3 rule). Partial breakdown → PRD STAYS in `prd/draft/`, tell user what remains.

When gate passes: move `prd/draft/NNNN_<slug>.md` → `prd/in-progress/NNNN_<slug>.md` (create folder if missing; `git mv` when repo tracks it). Task `Refs:` lines point at in-progress path.

### 6. Report

Reply with: PRD moved (old → new path), then one line per task — filename, type, mode, human flag, depends.
