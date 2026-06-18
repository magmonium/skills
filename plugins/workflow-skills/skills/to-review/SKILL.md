---
name: to-review
description: Pick the highest-NNNN feature folder in done state, verify each done issue against actual code, audit implemented code for security/architecture/DRY flaws, then create draft gap/refractor issues continuing that feature's NN sequence. Use when user says "to review", "review done tasks", or wants a finished feature verified against the codebase.
---

# To Review

Pick highest NNNN done task folder → tally its issues against real code → audit code for security/architecture/DRY flaws → gaps become draft issues, agreed findings become refractor issues, both continuing that NNNN's NN sequence inside the task folder.

Inverse of `/to-implement`: that skill moves work forward, this one checks finished work and reopens the feature with new draft issues when reality disagrees.

## 1. Pick feature folder

- Argument (`NNNN` or folder path) → use that NNNN.
- No argument → HIGHEST `NNNN_` prefix in `tasks/` top-level whose folder matches `NNNN_done_*`.
- No `NNNN_done_*` folders → tell user, stop.

Collect every `NN_*` issue file inside that folder. Issues still `NN_draft_*` while folder shows done → inconsistent state, report it, count those as gaps.

## 2. Tally issues vs code

Per done issue:

- Read **What** + **Acceptance Criteria** boxes.
- Verify in CODE, not in issue file ticks. Find implementation (grep/read modules the issue names), confirm each box's observable outcome actually exists. Ticked box ≠ proof.
- Run project test suite for touched area when cheap (use wrapper/commands from project CLAUDE.md).
- Verdict per issue: `complete` | `gap` (+ one line which criterion fails and why).

Also read `prd.md` — confirm every user story landed somewhere in an issue.

## 3. Audit implemented code

Scope: only modules/files this NNNN's issues touched — not whole repo. Check per [REVIEW-CHECKS.md](./REVIEW-CHECKS.md):

- **Security** — injection, authz/authn holes, secrets, unsafe input handling.
- **Architecture** — violates project ADRs/CLAUDE.md conventions (Signals, inject, Assets-first, `refractor`, no-commit), wrong layering, god-blob components.
- **DRY / reuse** — copy-paste blocks, logic duplicating existing shared helper, new code that should be reusable component.

Verdict per finding: location, problem, fix — one line each.

## 4. Create gap/refractor issues

Two kinds, different gates:

- **Gap issues** (step 2 failures) — create immediately, no asking. One issue per gap.
- **Refractor issues** (step 3 findings) — present findings to user first. Security findings: write in plain clear prose (auto-clarity, no caveman). User agrees → create issue. User rejects → drop it.

Issue files follow `grill-to-tasks` ISSUE-FORMAT.md, written into the same task folder (`tasks/NNNN_done_<desc>/`):

- Numbering: `NN_draft_<kebab-desc>.md` — NN = highest existing NN in that folder (any status) + 1, incrementing per new issue.
- Gap issue **What**: what's missing + observable criteria to confirm presence.
- Refractor issue **What**: names flaw + fix. Security **What** cites exact finding in plain prose.
- **Acceptance Criteria:** external behavior only, 2–5 boxes.
- **Blocked By:** list any prerequisite issue.

## 5. Report — caveman, minimal

- NNNN reviewed + verdict: `clean` | `reopened` (reopened = new draft issues added).
- Issue tally: N complete / M total, one line per gap.
- Findings: accepted / rejected counts, one line each accepted.
- New issue files (paths only).
- NO commit — user commits. No prose padding. Security details exempt from caveman.
- **Commit Hint:** If feature clean, provide draft merge message.
  ```
  feat(NNNN): <feature name> complete

  - all <M> issues verified in code
  - security and architecture audit passed
  - follows Magmonium Signals + refractor patterns

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor. Use `refractor`.
