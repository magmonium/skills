---
name: grill-to-tasks
description: Grill the user via grill-with-docs to align on a plan, then either implement directly (small) or create a task folder with plan.md + task files (large). Use when user wants to grill an idea straight into tasks, says "grill to tasks", or wants to skip the PRD step entirely.
disable-model-invocation: true
---

# Grill to Tasks

Two phases: grill to align, then assess — direct impl or task folder with plan + tasks.

## Phase 1 — Grill

Invoke `grill-with-docs` skill. Follow it exactly. Grill until shared understanding: domain aligned, terminology sharp, edge cases resolved, decisions captured. No open questions remain before moving to Phase 2.

## Phase 1.5 — Decide: direct or task folder?

After grill resolves, assess before writing any files:

**Implement directly** when ALL of:
- Single concern — fits one agent turn
- No new DB schema, no API contract negotiation between layers
- No meaningful dependency chain between pieces
- Change bounded to ≤ ~3 files or clear isolated layer

→ Say "Simple — implementing directly." Implement inline. No files created.

**Create task folder** when ANY of:
- Multiple concerns spanning FSD layers or repos
- DB schema or API contract to define first
- UI work requiring one-ui components or new screens
- Change touches > ~3 files across layers
- Human gate needed (design review, credentials, store approval)

## Phase 2 — Create task folder

### 1. Determine NNNN

Scan `tasks/` top-level for folders matching `NNNN_draft_*` and `NNNN_done_*`. NNNN = highest found + 1, zero-padded to 4 digits. None found → `0001`.

### 2. Create folder

`tasks/NNNN_draft_<kebab-desc>/` — 2–4 word kebab slug from grill. Example: `user-auth-flow`, `deploy-status-screen`.

### 3. Write plan.md

Write `tasks/NNNN_draft_<kebab-desc>/plan.md` — synthesize from grill session. Use exact domain vocabulary. No invented terms. No user stories.

Sections (in order):

```markdown
# NNNN — <Feature Title>

## Problem

What hurts. One precise paragraph.

## Architecture Decisions

Modules touched or created. Interfaces defined (inputs/outputs/contracts).
Seams introduced. Schema changes. API shapes. No file paths. No code snippets
(exception: prototype snippet encoding a decision more precisely than prose).

## Implementation Sequence

Ordered list of thin vertical slices. Each: what it delivers, what it unblocks.
Schema-first when applicable. Each slice demoable on its own.

## Testing

What makes a good test. Which modules get tests. Prior art in codebase.

## Out of Scope

What this plan explicitly does NOT cover.
```

### 4. Slice into tasks

Each task = one type (frontend | backend | integration | migration | one-ui) per slice. No open questions — make all decisions now. Format: see [TASK-FORMAT.md](./TASK-FORMAT.md).

**One UI** — for any slice touching frontend:
- Screen/page built → task type `frontend`, carries One UI section.
- Every screen MUST use `m-section` per logical region + `m-col` for responsive layout. No `grid-template-columns` in SASS for page-level structure.
- Component reusable across ≥2 features → separate `NNNN_SS_one-ui_<component>.md` task, screen task depends on it. Otherwise build locally. Decide now — no asking.
- One-ui task: PURELY presentational — inputs/outputs only, zero business logic, no API calls, no state.

**i18n** — for any slice with user-visible text in Angular templates:
- New UI strings → dedicated i18n task: run `/translate` on all new/modified templates.
- Keys renamed/deleted → migration step in that slice's task: update all `| translate` refs + YAML files so `i18n:compile` stays green.

**Migrations** — check before finalising:
- DB schema migration → include migration file in schema task.
- Data migration → backfill required → separate migration task with rollback plan.
- i18n key migration → coordinate with i18n task.
- API contract breaking change → note versioning strategy in affected task.

Task ordering: one-ui first (if any) → schema/migration → backend → frontend → i18n → integration. Sequence number (SS) = dependency order. Same SS = parallel.

### 5. Write task files

One file per task: `tasks/NNNN_draft_<task-desc>/NNNN_SS_<type>_<kebab-desc>.md`

Format: see [TASK-FORMAT.md](./TASK-FORMAT.md).

**WRITE CAVEMAN DIRECTLY.** All files (plan.md + every task) must be caveman-full from first keystroke.
- Drop articles, filler, pleasantries, hedging. Fragments OK. Short synonyms.
- Do NOT write verbose prose then compress — compress creates `.original.md` duplicates that clutter folder.
- Do NOT invoke `/compress` or `caveman:compress` after writing.

### 6. Report

NNNN + folder path. One line per task: filename, one-sentence what, blocked by.
