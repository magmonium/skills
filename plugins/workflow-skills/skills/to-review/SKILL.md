---
name: to-review
description: Pick highest-index PRD from prd/done/, verify each of its done tasks against actual code, audit implemented code for security/architecture/DRY flaws, then create draft gap/refactor tasks and move PRD back to prd/in-progress/ when work found. Use when user says "to review", "review done prd", or wants a finished epic verified against the codebase.
---

# To Review

Pick highest-numbered PRD from `prd/done/` → tally its done tasks against real code → audit code for security/architecture/DRY flaws → gaps become draft tasks, agreed findings become refactor tasks → any new task → PRD back to `prd/in-progress/`.

Inverse of `/to-implement`: that skill moves work forward, this one checks finished work and reopens the epic when reality disagrees.

## 1. Pick PRD

- Argument (index or path) → use that PRD.
- No argument → HIGHEST `NNNN_` prefix in `prd/done/` (newest finished epic).
- Folder empty/missing → tell user, stop.

Read PRD fully. Collect every `NNNN_*` task file for that index across `tasks/done/`, `tasks/in-progress/`, `tasks/draft/`. Tasks NOT in `tasks/done/` while PRD sits in `prd/done/` → inconsistent state, report it, count those as gaps.

## 2. Tally tasks vs code

Per done task:

- Read **What** + **Done When** boxes.
- Verify in CODE, not in task file ticks. Find the implementation (grep/read modules the task names), confirm each box's observable outcome actually exists. Ticked box ≠ proof.
- Run project test suite for touched area when cheap (use wrapper/commands from project CLAUDE.md).
- Verdict per task: `complete` | `gap` (+ one line which box fails and why).

## 3. Audit implemented code

Scope: only modules/files this PRD's tasks touched — not whole repo. Check per [REVIEW-CHECKS.md](./REVIEW-CHECKS.md):

- **Security** — injection, authz/authn holes, secrets, unsafe input handling.
- **Architecture** — violates project ADRs/CLAUDE.md conventions, wrong layering, god-blob components.
- **DRY / reuse** — copy-paste blocks, logic duplicating existing shared helper, new code that should be reusable component.

Verdict per finding: location, problem, fix — one line each.

## 4. Create tasks

Two kinds, different gates:

- **Gap tasks** (step 2 failures) — create immediately, no asking. One task per gap.
- **Refactor tasks** (step 3 findings) — present findings to user first. Security findings: write in plain clear prose (auto-clarity, no caveman). User agrees finding → create task. User rejects → drop it.

Task files follow `to-tasks` format ([TASK-FORMAT](../to-tasks/TASK-FORMAT.md)) in `tasks/draft/`:

- Numbering: `NNNN_SS_<type>_<kebab-desc>.md` — NNNN = PRD index, SS = highest existing SS for that NNNN (any folder) + 1.
- Gap task type: original vocabulary (backend/frontend/integration/…) matching what's missing.
- Refactor task type: `refactor`. **What** names the flaw + the fix; security refs the exact finding.
- **Refs:** PRD at its `prd/in-progress/` path (post-move), ADRs when finding leans on one.
- **Done When:** external behavior only, 2–5 boxes.

## 5. Move PRD

- ≥1 new task created → move `prd/done/NNNN_<slug>.md` → `prd/in-progress/` (create folder if missing; `git mv` when tracked).
- Zero tasks → PRD stays in `prd/done/`.

## 6. Report — caveman, minimal

- PRD id + verdict: `clean` | `reopened`.
- Task tally: N complete / M total, one line per gap.
- Findings: accepted / rejected counts, one line each accepted.
- New task files (paths only). PRD moved or stays.
- NO commit — user commits. No prose padding. Security details exempt from caveman.
