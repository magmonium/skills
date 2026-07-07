---
name: to-review
description: Pick the latest fully-checked plan file from tasks/, verify each task against actual code, audit implemented code for security/architecture/DRY flaws, then append new gap/refractor tasks continuing that plan's SS sequence. Use when user says "to review", "review done tasks", or wants a finished plan verified against the codebase.
---

# To Review

Pick the latest fully-`[x]` plan file → tally its tasks against real code → audit code for security/architecture/DRY flaws → gaps become new `[ ]` tasks, agreed findings become new `[ ]` refractor tasks, both appended to the same plan's `## Tasks` section, continuing its SS sequence.

Inverse of `/to-implement`: that skill moves work forward, this one checks finished work and reopens the plan by appending new unchecked tasks when reality disagrees.

## 1. Pick plan

- Argument (`NNNN` or file path) → use that plan.
- No argument → among `tasks/NNNN_*_plan.md` files where EVERY task heading checkbox is `[x]`, pick HIGHEST NNNN.
- None fully checked → tell user, stop.

Collect every task block in that plan's `## Tasks` section.

## 2. Tally tasks vs code

Per task:

- Read **What** + **Done When** boxes.
- Verify in CODE, not in ticks. Find implementation (grep/read modules the task names), confirm each box's observable outcome actually exists. Ticked box ≠ proof.
- Run project test suite for touched area when cheap (use wrapper/commands from project CLAUDE.md).
- Verdict per task: `complete` | `gap` (+ one line which criterion fails and why).

Also read the plan header's **Problem** — confirm it's actually solved end to end.

## 3. Audit implemented code

Scope: only modules/files this plan's tasks touched — not whole repo. Check per [REVIEW-CHECKS.md](./REVIEW-CHECKS.md):

- **Security** — injection, authz/authn holes, secrets, unsafe input handling.
- **Architecture** — violates project ADRs/CLAUDE.md conventions (Signals, inject, Assets-first, `refractor`, no-commit), wrong layering, god-blob components.
- **DRY / reuse** — copy-paste blocks, logic duplicating existing shared helper, new code that should be reusable component.

Verdict per finding: location, problem, fix — one line each.

## 4. Append gap/refractor tasks

Two kinds, different gates:

- **Gap tasks** (step 2 failures) — append immediately, no asking. One task per gap.
- **Refractor tasks** (step 3 findings) — present findings to user first. Security findings: write in plain clear prose (auto-clarity, no caveman). User agrees → append task. User rejects → drop it.

New task blocks follow `grill-to-tasks`'s PLAN-FORMAT.md task-block format, appended at the end of the plan's `## Tasks` section:

- Numbering: `NNNN_SS` — SS = highest existing SS in that plan + 1, incrementing per new task.
- Gap task **What**: what's missing + observable criteria to confirm presence.
- Refractor task **What**: names flaw + fix. Security **What** cites exact finding in plain prose.
- **Done When:** external behavior only, 2–5 boxes.
- **Depends:** any prerequisite task.
- Heading checkbox starts `[ ]` — appending an unchecked task is what reopens the plan. No renames, no file moves.

## 5. Report — caveman, minimal

- NNNN reviewed + verdict: `clean` | `reopened` (reopened = new tasks appended).
- Task tally: N complete / M total, one line per gap.
- Findings: accepted / rejected counts, one line each accepted.
- New task ids appended (NNNN_SS list — same file, no new paths).
- NO commit — user commits. No prose padding. Security details exempt from caveman.
- **Commit Hint:** If plan clean, provide draft merge message.
  ```
  feat(NNNN): <feature name> complete

  - all <M> tasks verified in code
  - security and architecture audit passed
  - follows Magmonium Signals + refractor patterns

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor. Use `refractor`.
