---
name: to-implement
description: Pick lowest-index ready task from tasks/draft/, move it to tasks/in-progress/, implement it straight following existing codebase patterns, then move it to tasks/done/. Use when user says "to implement", "implement next task", or wants the next drafted task built directly (no TDD).
---

# To Implement

Pick next ready task from `tasks/draft/` → move to `tasks/in-progress/` → implement → `tasks/done/`.

Sibling: `/tdd-implement` — same lifecycle, TDD red-green-refactor instead of straight build.

## 1. Pick task

- Argument (task id `NNNN_SS` or path) → use that task, wherever it sits (`tasks/in-progress/` or `tasks/draft/`).
- No argument → check `tasks/in-progress/` FIRST. Task there → resume it: read task file, see which **Done When** boxes already ticked, diff code vs task to gauge real progress (boxes may lag code — verify), finish remaining work only. Multiple → lowest `NNNN_SS`. Task waiting ONLY on pending human step → report step, skip it, fall through to draft pick.
- `tasks/in-progress/` empty → lowest `NNNN_SS` in `tasks/draft/` whose **Depends** are ALL in `tasks/done/`.
- Tasks exist but none eligible → list what blocks each, stop.
- Both folders empty/missing → tell user, stop.

Draft pick → move file `tasks/draft/` → `tasks/in-progress/` (create folder if missing; `git mv` when tracked). Resumed task already there — no move. Then start.

## 2. Read context

- Task file fully — **Context** section carries the why (no PRD). Then its **Refs** — ADRs listed, if any.
- **Depends** tasks in `tasks/done/` — esp. `Mode: reference` ones (modelling contracts).
- Explore code around the change: existing patterns, reusable components, theme, API/model conventions, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

## 3. Implement

Straight build. No test-first ceremony — add tests only where project convention expects them.

Rules:

- **Magmonium Standard:** Use Signals (`signal`, `computed`, `effect`) for state. No `standalone: true` (Ng 19+ default). Use `inject()` for DI; no constructor injection. Use `ChangeDetectionStrategy.OnPush`.
- **Assets First:** Never hardcode UI config (buttons, forms, navs) in TS. Define in `mag_assets/*.yml`. Run `npm run assets:compile`.
- **UI Components:** No native `<h1>-<h6>`, `<button>`, `<input>`, or `<img>`. Use `m-header`, `m-button`, `m-input`, `m-img`.
- **Text:** All text via `| translate` pipe — no raw strings in templates.
- **Styling:** `.sass` only (no `.css`), BEM naming, max 3 nesting levels. Import `@use 'index' as m`.
- **FSD Layering:** `pages` → `widgets` → `features` → `entities` → `shared`.
- DRY, efficient, modern idiom for the stack. Smallest diff that satisfies task.
- Follow per-type rules in task file (mock data for frontend, contract from modelling task, etc.).

## 4. Verify

- Every **Done When** box except final gate: check, tick in task file.
- **Translation lint errors:** Agent NEVER runs `translation:fix`. If lint fails **only** on translation errors → tell user to run it, stop, wait for user to confirm it's done. Once confirmed → re-run lint, tick remaining boxes, proceed to close + commit (step 7).
- Final gate (human-in-loop): agent never runs translation:fix/asset compile/build/test. List exact commands, stop, wait. OK → tick gate, proceed to close + commit.

## 5. Close task

- `Human:` ≠ none and human step pending (translation fix, asset compile, build, test) → task STAYS in `tasks/in-progress/`, report exact human step. Once user confirms step done → move task → `tasks/done/`, run git commit (step 7).
- Else move task file → `tasks/done/` (create folder if missing).

## 6. Feature status

No `NNNN_*` tasks left in `tasks/draft/` or `tasks/in-progress/` for this NNNN → feature fully done, ready for `/to-review`. Else note remaining count.

## 7. Report — caveman, minimal

- Task id + one line what built. Files touched (paths only).
- Done When: each box pass/fail.
- Feature: N done / M total tasks for this NNNN.
- **Commit:** Run `git add` on changed files, then `git commit` with message:
  ```
  <type>(<NNNN_SS>): <what, terse, fragments>

  <one-line why, caveman>

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor/chore. `refractor` MUST be used instead of `refactor`.
