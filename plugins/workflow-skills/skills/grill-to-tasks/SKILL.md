---
name: grill-to-tasks
description: Grill the user via grill-with-docs to align on a plan, then either implement directly (small) or create a task folder with plan.md + issue files (large). Use when user wants to grill an idea straight into tasks, says "grill to tasks", or wants to skip the PRD step entirely.
disable-model-invocation: true
---

# Grill to Tasks

Two phases: grill to align, then assess — direct impl or task folder with plan + issues.

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

### 4. Slice into issues

Each issue = thin slice through ALL layers needed (schema + endpoint + UI when part of same concern). Each slice demoable or verifiable on its own. No open questions — make all decisions now.

**One UI** — for any slice touching frontend:
- Screen/page built → issue carries `## One UI` section (see ISSUE-FORMAT.md).
- Every screen MUST use `m-section` per logical region + `m-col` for responsive layout. No `grid-template-columns` in SASS for page-level structure.
- Component reusable across ≥2 features → separate `NN_draft_one-ui-<component>.md` issue, screen depends on it. Otherwise build locally. Decide now — no asking.
- One-ui issue: PURELY presentational — inputs/outputs only, zero business logic, no API calls, no state.

**i18n** — for any slice with user-visible text in Angular templates:
- New UI strings → dedicated i18n issue: run `/translate` on all new/modified templates.
- Keys renamed/deleted → migration step in that slice's issue: update all `| translate` refs + YAML files so `i18n:compile` stays green.

**Migrations** — check before finalising:
- DB schema migration → include migration file in schema issue.
- Data migration → backfill required → separate issue with rollback plan.
- i18n key migration → coordinate with i18n issue.
- API contract breaking change → note versioning strategy in affected issue.

**No FE/BE type split** — one issue per concern. Schema before UI when coupled: dependency, not separate issue.

Issue ordering: one-ui first (if any) → schema/migration → backend → UI/screen → i18n → integration. Sequence number = dependency order.

### 5. Write issue files

One file per issue: `tasks/NNNN_draft_<task-desc>/NN_draft_<kebab-issue-desc>.md`

Format: see [ISSUE-FORMAT.md](./ISSUE-FORMAT.md).

Apply caveman-full compression to plan.md and all issue files while writing:
- Drop articles, filler, pleasantries, hedging. Fragments OK. Short synonyms.

### 6. Report

NNNN + folder path. One line per issue: filename, one-sentence what, blocked by.
