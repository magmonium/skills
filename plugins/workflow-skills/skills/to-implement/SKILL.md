---
name: to-implement
description: Pick the latest plan file from tasks/ (or a given NNNN or NNNN_SS task), pick its first unblocked unchecked task (or the given one), implement it straight following existing codebase patterns, then check it off. Use when user says "to implement", "implement next task", "implement NNNN_SS", or wants the next undone task built directly (no TDD).
---

# To Implement

Pick plan file → pick task (given task id, or first unblocked `[ ]` in dependency order) → implement → tick its Done-When boxes and its own checkbox.

Sibling: `/tdd-implement` — same lifecycle, TDD red-green-refactor instead of straight build.

## 1. Pick plan + task

**Argument given:**
- `NNNN_SS` (task id) → use plan `NNNN`, target that exact task. Already `[x]` → tell user, stop. **Depends** unmet → report blocker, stop.
- `NNNN` (plan number) or file path → use that plan file, then auto-pick per below.

**No argument** → auto-pick:
- Scan `tasks/` top-level for files matching `NNNN_*_plan.md`. Pick HIGHEST NNNN (latest).
- No plan files → tell user, stop.

**Auto-pick inside the chosen plan's `## Tasks` section** (walk top to bottom — file order = dependency order):
- Pick the first task whose heading checkbox is `[ ]` AND every task named in its **Depends** is `[x]`.
- No `[ ]` task found → plan fully done, tell user, ready for `/to-review`, stop.
- First `[ ]` task's **Depends** unmet → skip it, try the next `[ ]` task. None unblocked → list blockers, stop.

## 2. Read context

- Plan header — **Problem**, **Architecture Decisions**, **Testing**, **Out of Scope** — overall feature context.
- The chosen task block fully — **Context**, **What**, **Done When**.
- Explore code around the change: existing patterns, reusable components, theme, API/model conventions, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

## 3. Implement

Straight build. No test-first ceremony — add tests only where project convention expects them.

Rules:

- **Magmonium Standard:** Use Signals (`signal`, `computed`, `effect`) for state. No `standalone: true` (Ng 19+ default). Use `inject()` for DI; no constructor injection. Use `ChangeDetectionStrategy.OnPush`.
- **Assets First:** Never hardcode UI config (buttons, forms, navs) in TS. Define in `mag_assets/*.yml`. Run `npm run assets:compile`.
- **UI Components:** No native `<h1>-<h6>`, `<button>`, `<input>`, or `<img>`. Use `m-header`, `m-button`, `m-input`, `m-img`.
- **Page Layout:** All page/screen area segregation via `m-section` + `m-col` (12-col responsive grid). No hand-rolled CSS grid or `grid-template-columns` for top-level layout. Use `m-section-header` for sticky section titles. `m-col` breakpoint inputs (`xs`/`sm`/`md`/`lg`/`xl`/`xxl`) = the ONLY way to control responsiveness.
- **Text:** All text via `| translate` pipe — no raw strings in templates.
- **Styling:** `.sass` only (no `.css`), BEM naming, max 3 nesting levels. Import `@use 'index' as m`.
- **FSD Layering:** `pages` → `widgets` → `features` → `entities` → `shared`.
- DRY, efficient, modern idiom for the stack. Smallest diff that satisfies the task.
- If task has **One UI** content in What: follow those constraints exactly.

## 4. Verify

- Every **Done When** box except the final gate: check, tick in the plan file.
- **Translation lint errors:** Agent NEVER runs `translation:fix`. Lint fails only on translation errors → tell user to run it, stop, wait. User confirms done → re-run lint, tick remaining boxes, proceed to close + commit (step 5).
- Final gate (human build/lint/test): agent never runs translation:fix/asset compile/build/test. List exact commands, stop, wait. OK → tick the gate box, proceed.

## 5. Mark done (or leave open)

**On success:**
- Human gate pending → report exact human step. Wait for user to confirm done, then proceed.
- Tick the task's own `[ ]` → `[x]` heading checkbox.
- Any `[ ]` task remain in the plan? Yes → note how many remain, stop. No → tell user the plan is fully done, ready for `/to-review`.

**On failure / blocked / abandoned:**
- Leave the task's heading checkbox `[ ]`. Report what failed. Stop.

## 6. Report — caveman, minimal

- Task id (`NNNN_SS`) + one line what built. Files touched (paths only).
- Done When: each box pass/fail.
- Plan: N done / M total tasks for this NNNN.
- **Commit:** Run `git add` on changed files, then `git commit` with message:
  ```
  <type>(NNNN/SS)- <what, terse, fragments>

  <one-line why, caveman>

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor/chore. `refractor` MUST be used instead of `refactor`.
