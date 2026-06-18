---
name: grill-to-tasks
description: Grill the user via grill-with-docs to align on a plan, then either implement directly (small) or create a task folder with prd.md + issue files (large). Use when user wants to grill an idea straight into tasks, says "grill to tasks", or wants to skip the PRD step entirely.
---

# Grill to Tasks

Two phases: grill to align, then assess — direct impl or task folder with PRD + issues.

## Phase 1 — Grill

Invoke `grill-with-docs` skill. Follow it exactly. Grill until shared understanding: domain aligned, terminology sharp, edge cases resolved, decisions captured.

## Phase 1.5 — Decide: direct or task folder?

After grill resolves, assess before writing any files:

**Implement directly** when ALL of:
- Single concern — fits one agent turn
- No new DB schema, no API contract negotiation between layers
- No meaningful dependency chain between pieces
- Change bounded to ≤ ~3 files or clear isolated layer

→ Tell user "Simple — implementing directly." Then implement inline. No files created.

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

Create: `tasks/NNNN_draft_<kebab-desc>/`

`<kebab-desc>` = 2–4 word kebab slug of the feature from grill session. Example: `user-auth-flow`, `deploy-status-screen`.

### 3. Write prd.md

Write `tasks/NNNN_draft_<kebab-desc>/prd.md` — synthesize from grill session. Use exact domain vocabulary from grill. No invented terms.

Sections (in order):

```markdown
# NNNN — <Feature Title>

## Problem Statement

What hurts. From the user's perspective.

## Solution

What fixes it. From the user's perspective.

## User Stories

Numbered list. Each: "As a <actor>, I want <feature>, so that <benefit>."
Be extensive — cover all aspects of the feature.

## Implementation Decisions

Modules to build or modify. Interfaces. API contracts (request/response shapes).
Schema changes. Architectural decisions. Specific interactions.
NO file paths. NO code snippets (exception: prototype snippet that encodes a decision
more precisely than prose — inline it, note it came from grill/prototype).

## Testing Decisions

What makes a good test. Which modules get tests. Prior art in codebase.

## Out of Scope

What this PRD explicitly does NOT cover.
```

### 4. Slice into issues

Break PRD into self-completeable vertical slices. Each issue = thin slice cutting through ALL layers needed (schema + endpoint + UI when part of same thin slice). Each slice demoable or verifiable on its own.

**One UI check** — for any slice touching frontend:
- Screen/page built → issue must carry a `## One UI` section (see ISSUE-FORMAT.md).
- Reusable component candidate (useful beyond this feature) → ASK USER: "X looks reusable — build as a One UI library component?" Yes → separate issue `NN_draft_one-ui-<component>.md`, screen issue depends on it. No → build locally inside app in the screen issue.
- One-ui issue: PURELY presentational — inputs/outputs only, zero business logic, no API calls, no state.

**No FE/BE type split** — one issue per concern. If schema must land before UI can start, separate them with a dependency. If tightly coupled, one issue covers all layers.

Issue ordering: one-ui issues first (if any) → schema/backend → UI/screen → integration (if needed). Sequence number = dependency order.

### 5. Write issue files

One file per issue: `tasks/NNNN_draft_<task-desc>/NN_draft_<kebab-issue-desc>.md`

Format: see [ISSUE-FORMAT.md](./ISSUE-FORMAT.md). Keep files small — agent reads in seconds.

### 6. Report

NNNN chosen + why (highest found + 1, or 0001). Folder path created. One line per issue: filename, one-sentence what, blocked by.
