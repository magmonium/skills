---
name: to-review
description: Pick the highest-NNNN feature whose tasks are fully in tasks/done/, verify each done task against actual code, audit the implemented code for security/architecture/DRY flaws, then create draft gap/refractor tasks continuing that feature's SS sequence. Use when user says "to review", "review done tasks", or wants a finished feature verified against the codebase.
---

# To Review

Pick the highest NNNN feature group sitting in `tasks/done/` → tally its tasks against real code → audit code for security/architecture/DRY flaws → gaps become draft tasks, agreed findings become refractor tasks, both continuing that NNNN's SS sequence in `tasks/draft/`.

Inverse of `/to-implement`: that skill moves work forward, this one checks finished work and reopens the feature with new draft tasks when reality disagrees.

## 1. Pick feature group

- Argument (`NNNN` or path) → use that NNNN.
- No argument → HIGHEST `NNNN_` prefix appearing in `tasks/done/`.
- `tasks/done/` empty/missing → tell user, stop.

Collect every `NNNN_*` task file for that NNNN across `tasks/done/`, `tasks/in-progress/`, `tasks/draft/`. Tasks NOT in `tasks/done/` while this NNNN is being reviewed → inconsistent state, report it, count those as gaps.

## 2. Tally tasks vs code

Per done task:

- Read **Context** + **What** + **Done When** boxes.
- Verify in CODE, not in task file ticks. Find the implementation (grep/read modules the task names), confirm each box's observable outcome actually exists. Ticked box ≠ proof.
- Run project test suite for touched area when cheap (use wrapper/commands from project CLAUDE.md).
- Verdict per task: `complete` | `gap` (+ one line which box fails and why).

## 3. Audit implemented code

Scope: only modules/files this NNNN's tasks touched — not whole repo. Check per [REVIEW-CHECKS.md](./REVIEW-CHECKS.md):

- **Security** — injection, authz/authn holes, secrets, unsafe input handling.
- **Architecture** — violates project ADRs/CLAUDE.md conventions (Signals, inject, Assets-first, `refractor`, no-commit), wrong layering, god-blob components.
- **DRY / reuse** — copy-paste blocks, logic duplicating existing shared helper, new code that should be reusable component.

Verdict per finding: location, problem, fix — one line each.

## 4. Create tasks

Two kinds, different gates:

- **Gap tasks** (step 2 failures) — create immediately, no asking. One task per gap.
- **Refractor tasks** (step 3 findings) — present findings to user first. Security findings: write in plain clear prose (auto-clarity, no caveman). User agrees finding → create task. User rejects → drop it.

Task files follow `grill-to-tasks` format, written to `tasks/draft/`:

- Numbering: `NNNN_SS_<type>_<kebab-desc>.md` — NNNN = the feature being reviewed, SS = highest existing SS for that NNNN (any folder) + 1, incrementing per new task.
- Gap task type: original vocabulary (backend/frontend/integration/…) matching what's missing.
- Refractor task type: `refractor`. **What** names the flaw + the fix; security refs the exact finding.
- **Context:** 2–4 lines — what's missing/wrong and why, distilled from the gap or finding. No PRD to point at.
- **Refs:** ADRs only, when finding leans on one. Omit if none.
- **Done When:** external behavior only, 2–5 boxes.

## 5. Report — caveman, minimal

- NNNN reviewed + verdict: `clean` | `reopened` (reopened = new draft tasks added).
- Task tally: N complete / M total, one line per gap.
- Findings: accepted / rejected counts, one line each accepted.
- New task files (paths only).
- NO commit — user commits. No prose padding. Security details exempt from caveman.
- **Commit Hint:** If feature clean, provide draft merge message.
  ```
  feat(<NNNN>): <feature name> complete

  - all <M> tasks verified in code
  - security and architecture audit passed
  - follows Magmonium Signals + refractor patterns

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor. Use `refractor`.
