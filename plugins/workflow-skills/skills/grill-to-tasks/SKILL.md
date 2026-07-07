---
name: grill-to-tasks
description: Grill the user via grill-with-docs to align on a plan, then either implement directly (small) or write a single plan file with embedded checkbox tasks (large). Use when user wants to grill an idea straight into tasks, says "grill to tasks", or wants to skip the PRD step entirely.
disable-model-invocation: true
---

# Grill to Tasks

Two phases: grill to align, then assess — direct impl or one plan file holding ordered checkbox tasks.

## Phase 1 — Grill

Invoke `grill-with-docs` skill. Follow it exactly. Grill until shared understanding: domain aligned, terminology sharp, edge cases resolved, decisions captured. No open questions remain before moving to Phase 2.

## Phase 1.5 — Decide: direct or plan file?

After grill resolves, assess before writing any files:

**Implement directly** when ALL of:
- Single concern — fits one agent turn
- No new DB schema, no API contract negotiation between layers
- No meaningful dependency chain between pieces
- Change bounded to ≤ ~3 files or clear isolated layer

→ Say "Simple — implementing directly." Implement inline. No files created.

**Write plan file** when ANY of:
- Multiple concerns spanning FSD layers or repos
- DB schema or API contract to define first
- UI work requiring one-ui components or new screens
- Change touches > ~3 files across layers
- Human gate needed (design review, credentials, store approval)

## Phase 2 — Write plan file

### 1. Determine NNNN

Scan `tasks/` top-level for files matching `NNNN_*_plan.md`. NNNN = highest found + 1, zero-padded to 4 digits. None found → `0001`.

### 2. Write the file

`tasks/NNNN_<kebab-desc>_plan.md` — one flat file. No folder, no separate task files. 2–4 word kebab slug from grill. Example: `0007_deploy-status-plan.md`.

Format: see [PLAN-FORMAT.md](./PLAN-FORMAT.md). Header sections (Problem, Architecture Decisions, Testing, Out of Scope) synthesize the grill session — exact domain vocabulary, no invented terms, no user stories, no file paths in Architecture Decisions (exception: prototype snippet encoding a decision more precisely than prose).

### 3. Slice into tasks

Each task = one type (frontend | backend | integration | migration | one-ui) per slice. No open questions — make all decisions now.

**One UI** — for any slice touching frontend:
- Screen/page built → task type `frontend`, carries One UI section.
- Every screen MUST use `m-section` per logical region + `m-col` for responsive layout. No `grid-template-columns` in SASS for page-level structure.
- Component reusable across ≥2 features → separate `one-ui` task, screen task depends on it. Otherwise build locally. Decide now — no asking.
- One-ui task: PURELY presentational — inputs/outputs only, zero business logic, no API calls, no state.

**i18n** — for any slice with user-visible text in Angular templates:
- New UI strings → dedicated i18n task: run `/translate` on all new/modified templates.
- Keys renamed/deleted → migration step in that slice's task: update all `| translate` refs + YAML files so `i18n:compile` stays green.

**Migrations** — check before finalising:
- DB schema migration → include migration file in schema task.
- Data migration → backfill required → separate migration task with rollback plan.
- i18n key migration → coordinate with i18n task.
- API contract breaking change → note versioning strategy in affected task.

Task order = dependency order, top to bottom, in the `## Tasks` section — this ordering IS the build order. `/to-implement` and `/tdd-implement` walk it top-down; `/to-review` appends new tasks at the bottom continuing the sequence. One-ui first (if any) → schema/migration → backend → frontend → i18n → integration. Sequence number (SS) = dependency order. Same SS = parallel — sit adjacent, each notes the other in **Depends** as `parallel: NNNN_SS`.

### 4. Write the Tasks section

Append every task block under one `## Tasks` heading, in dependency order. One `### [ ] NNNN_SS — <Title>` per task. Format: see [PLAN-FORMAT.md](./PLAN-FORMAT.md).

**WRITE CAVEMAN DIRECTLY.** Whole plan file — header sections + every task block — caveman-full from first keystroke.
- Drop articles, filler, pleasantries, hedging. Fragments OK. Short synonyms.
- Do NOT write verbose prose then compress — compress creates `.original.md` duplicates.
- Do NOT invoke `/compress` or `caveman:compress` after writing.

### 5. Report

NNNN + file path. One line per task: id, title, depends.
