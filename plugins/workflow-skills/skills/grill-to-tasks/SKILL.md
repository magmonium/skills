---
name: grill-to-tasks
description: Interview the user relentlessly about a plan or feature until shared understanding, then slice it directly into at most four typed task files (frontend, backend, integration, migration — plus optional one-ui) under tasks/draft/. No PRD step. Numbering NNNN_SS — NNNN = highest existing across tasks/draft, tasks/in-progress, tasks/done, plus one. Use when user wants to grill an idea straight into tasks, says "grill to tasks", or wants to skip the PRD step entirely.
---

# Grill to Tasks

Two phases: grill, then slice straight into task files. No PRD, no issue tracker — output is task files in `tasks/draft/`, each carrying its own context.

## Phase 1 — Grill

Interview the user relentlessly about every aspect of the plan until shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask questions one at a time, waiting for an answer before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead of asking.

Track resolved decisions as you go — they feed the tasks' **Context** sections and **Done When** boxes. Also track: problem (what hurts), solution (what fixes it), user stories, testing approach, out-of-scope items.

## Phase 2 — Slice into tasks

When all branches are resolved (or user says "write the tasks" / "enough"):

### 1. Determine NNNN

Scan `tasks/draft/`, `tasks/in-progress/`, `tasks/done/` for `NNNN_` prefixes. NNNN = highest found + 1, zero-padded to 4 digits. None found anywhere → `0001`.

### 2. Explore codebase

Find: existing reusable components (One UI library first), theme, API patterns, i18n setup, model conventions. Task descriptions must use real project vocabulary, not invented names.

### 3. Slice into tasks — MAX FOUR

Fixed task set. Create each ONLY when the feature needs it (pure-backend feature → no frontend/integration task; etc.):

| # | Type | Job |
|---|------|-----|
| 1 | `frontend` | Pure FE. Screen/UI with MOCK data — zero API calls. Use One UI components + One UI knowledge to make screen beautiful. SAME task handles assets (icons, images, illustrations) AND translations — body must instruct agent to run `/translate` skill after UI built. Code compiles, lint passes. |
| 2 | `backend` | API endpoints, business logic, DB changes. Defines contract (request/response shapes) frontend will later bind to. Runs PARALLEL with frontend — frontend mocked, no dependency between them. |
| 3 | `integration` | Swap frontend mocks for real backend API. Wire end-to-end: loading/error states, real data in, mocks out, feature actually works. Depends on frontend + backend. |
| 4 | `migration` | Stabilization pass over WHOLE implementation. Hunt deviations: code architecture (FSD layering, module boundaries), DRY violations, security issues; run `/fe-review` skill on FE delta. Fix/migrate what found — code stable + beautiful. OPTIONAL — skip when implementation small/clean. Depends on integration. |

One UI reusable-component check — do DURING slicing, before writing files:

- Shaping frontend task → scan the feature's UI for pieces reusable beyond this feature (generic card, picker, status badge…).
- Candidate found → ASK USER: "X looks reusable — create One UI component task for it?"
- Yes → add `one-ui` task: build component in One UI library; frontend task depends on it.
- `one-ui` task is PURELY presentational — UI/UX + aesthetics ONLY. Zero business logic: no API calls, no state management, no domain rules, no feature-specific behavior. Component takes data via inputs, emits events via outputs — consumer (frontend task) owns all logic. Task body must state this constraint.
- No → frontend task builds it locally inside the app.

Rules:

- Full coverage: every user story / decision from the grill lands in some task. Nothing left unassigned.
- Each task lists what blocks it. Sequence number = dependency order.
- Task needing human (design review, credentials, store approval, manual QA) → mark `Human:` with what human must do. Prefer no-human tasks.
- Every task carries its own **Context** (see TASK-FORMAT.md) — no PRD to refer back to.

UI rules (frontend + one-ui tasks must state them):

- Minimal HTML/CSS — reuse One UI / app components before writing new markup.
- New UI → small reusable components, not one big blob.
- Logic out of templates — functions separate, components thin.
- Follow FSD (Feature-Sliced Design) layering of the app.

Order: one-ui (if any) → frontend ∥ backend → integration → migration (if any).

### 4. Write task files

Numbering: `NNNN_SS_<type>_<kebab-desc>.md` in `tasks/draft/` — NNNN from step 1, SS = 2-digit sequence in dependency order (01 first). Create folder if missing.

Format per task: see [TASK-FORMAT.md](./TASK-FORMAT.md). Prose caveman: drop articles/filler/hedging, fragments OK, technical terms exact.

### 5. Report

Reply with: NNNN chosen + why (highest found + 1, or 0001), then one line per task — filename, type, mode, human flag, depends. Note migration task skipped + why, when skipped.
