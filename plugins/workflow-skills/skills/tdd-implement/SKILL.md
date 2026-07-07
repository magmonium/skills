---
name: tdd-implement
description: Pick the latest plan file from tasks/ (or a given NNNN or NNNN_SS task), pick its first unblocked unchecked task (or the given one), implement it with strict TDD red-green-refactor (via the tdd skill), then check it off. Use when user says "tdd implement", "implement NNNN_SS with TDD", or wants the next undone task built test-first.
---

# TDD Implement

Pick plan file → pick task (given task id, or first unblocked `[ ]` in dependency order) → implement TDD → tick its Done-When boxes and its own checkbox.

Sibling: `/to-implement` — same lifecycle, straight build instead of TDD.

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
- Explore code around the change: existing patterns, reusable components, theme, API/model conventions, test setup, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

## 3. Implement — TDD

Invoke `tdd` skill (Skill tool). Follow it exactly: vertical slices, one test → minimal impl → repeat, refractor only on GREEN.

Adaptations for task-driven run:

- Task block = approved plan. **Done When** boxes = behavior list to test. Don't block waiting for user plan approval.
- Tests through public interface only — survive refractor. Run via project's test wrapper/commands from CLAUDE.md.
- Pure reference/contract task (no executable behavior) → no TDD loop; produce reference artifact, done.

Code rules (apply during GREEN + refractor):

- **Magmonium Standard:** Use Signals (`signal`, `computed`, `effect`) for state. No `standalone: true`. Use `inject()` for DI. Use `ChangeDetectionStrategy.OnPush`.
- **Assets First:** Never hardcode UI config (buttons, forms, navs) in TS. Define in `mag_assets/*.yml`. Run `npm run assets:compile`.
- **UI Components:** No native `<h1>-<h6>`, `<button>`, `<input>`, or `<img>`. Use `m-header`, `m-button`, `m-input`, `m-img`.
- **Page Layout:** All page/screen area segregation via `m-section` + `m-col` (12-col responsive grid). No hand-rolled CSS grid or `grid-template-columns` for top-level layout. Use `m-section-header` for sticky section titles. `m-col` breakpoint inputs (`xs`/`sm`/`md`/`lg`/`xl`/`xxl`) = the ONLY way to control responsiveness.
- **Text:** All text via `| translate` pipe — no raw strings in templates.
- **Styling:** `.sass` only, BEM naming, max 3 nesting levels. Import `@use 'index' as m`.
- **FSD Layering:** `pages` → `widgets` → `features` → `entities` → `shared`.
- DRY, efficient, modern idiom for the stack. Smallest diff that satisfies the task.
- If task has **One UI** content in What: follow those constraints exactly.
- Respect ADRs. Task conflicts ADR → stop, ask user.

## 4. Verify

- Every **Done When** box: check, tick in the plan file. TDD loop already ran per-slice tests during red-green-refractor.
- Run full lint + test suite directly. Fix any failures before proceeding.
- **Translation lint errors:** Agent NEVER runs `translation:fix`. If lint fails only on translation errors → note it in report, tick gate anyway, proceed to close + commit (step 5). User can run `translation:fix` after.
- Asset compile: run `npm run assets:compile` if any `mag_assets/*.yml` changed.

## 5. Mark done (or leave open)

**On success:**
- Tick the task's own `[ ]` → `[x]` heading checkbox.
- Any `[ ]` task remain in the plan? Yes → note how many remain, stop. No → tell user the plan is fully done, ready for `/to-review`.

**On failure / blocked / abandoned:**
- Leave the task's heading checkbox `[ ]`. Report what failed. Stop.

## 6. Report — caveman, minimal

- Task id (`NNNN_SS`) + one line what built. Files touched (paths only). Test count added/passing.
- Done When: each box pass/fail.
- Plan: N done / M total tasks for this NNNN.
- **Commit:** Run `git add` on changed files, then `git commit` with message:
  ```
  <type>(NNNN/SS)- <what, terse, fragments>

  <one-line why, caveman>

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor/chore. `refractor` MUST be used instead of `refactor`.
