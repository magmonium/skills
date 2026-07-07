---
name: to-implement
description: Pick the latest plan file from tasks/ (or a given NNNN plan or NNNN_SS task), then loop every unblocked task top to bottom — implementing each straight, following existing codebase patterns — ticking it off and committing. Same-SS tasks run in parallel via subagents. AFK tasks (Human: none) verify and continue unattended; HIL tasks stop and ask. Plan fully done → git push. Use when user says "to implement", "implement next task", "implement NNNN_SS", "run tasks AFK", or wants the plan built end to end.
---

# To Implement

Pick plan file → loop every unblocked task in dependency order (same-SS tasks run in parallel) → implement → tick Done-When boxes + heading checkbox → commit. AFK task (`Human: none`) continues straight to the next task, no stop. HIL task (`Human: <step>`) stops, asks, waits, then resumes. Plan fully done → git push.

Sibling: `/tdd-implement` — same lifecycle, TDD red-green-refactor instead of straight build.

## 1. Pick plan + mode

**Argument = task id (`NNNN_SS`)** → single-task mode. Use plan `NNNN`, target that exact task only. Already `[x]` → tell user, stop. **Depends** unmet → report blocker, stop. Run steps 3a–5 once for this task, then stop — no loop, no push.

**Argument = plan number/path, or no argument** → loop mode.
- Given plan number/path → use it. No argument → scan `tasks/` top-level for `NNNN_*_plan.md`, pick HIGHEST NNNN (latest). None found → tell user, stop.
- Go to step 2.

## 2. Loop — pick next task(s)

Walk the plan's `## Tasks` section top to bottom (file order = dependency order):

- Find task(s) whose heading is `[ ]` AND every id in **Depends** is `[x]`.
- Two or more of those share the same SS and note each other `parallel: NNNN_SS`? → **parallel group** → step 3b.
- Otherwise → single next task → step 3a.
- No `[ ]` task found → plan fully done → step 6 (push).
- Remaining `[ ]` tasks all blocked (Depends unmet) → list blockers, stop. No push.

## 3a. Implement — single task

Read context: plan header (**Problem**, **Architecture Decisions**, **Testing**, **Out of Scope**) + this task's full block (**Context**, **What**, **Done When**). Explore code around the change: existing patterns, reusable components, theme, API/model conventions, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

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

Go to step 4.

## 3b. Implement — parallel group

For each task in the group: dispatch one `Agent` (subagent_type = `angular-fsd-expert` for frontend/one-ui tasks, `general-purpose` otherwise). Dispatch ALL of them in a single message — true parallel — `run_in_background: false`, wait for all to return before continuing.

Each subagent's prompt carries: plan header context, the task's full block (**Context**/**What**/**Done When**), the Rules list from step 3a, and an explicit instruction to implement code only — **no git commands, no editing the plan file, no commit**. Subagent reports back files touched + which Done-When boxes it believes pass.

Once all subagents return: verify + tick + commit each task in the group **sequentially**, in the order it appears in the plan (avoids concurrent git operations on the same repo). Run step 4 once per task.

## 4. Verify

Run the task's Done-When gate commands (build/lint/test — from CLAUDE.md/package.json/repo scripts, never invented) **yourself**. Fix failures, re-run, until they pass.

- **Translation lint errors — sole exception:** agent NEVER runs `translate`/`translation:fix` (API-key/cost gated). Failure isolated to translation lint → tell user to run it, stop the loop, wait. User confirms done → re-run lint, tick remaining boxes, continue.
- All other build/lint/test/asset-compile failures: agent fixes and re-verifies itself. Can't converge after reasonable attempts → leave heading `[ ]`, report what failed, stop the loop entirely. No push.
- Task's **Human** field is not `none` (HIL task): finish every other box, then stop for the named human step — state exactly what's needed, wait. User confirms → tick gate + heading, go to step 5. User says broken → fix, re-ask, wait again.
- Task's **Human** field is `none` (AFK task): agent completes verification itself, ticks every box including the gate — no stop.

## 5. Tick + commit

- Tick every passed **Done When** box, then the task's own `[ ]` → `[x]` heading checkbox.
- `git add` the changed files, `git commit`:
  ```
  <type>(NNNN/SS)- <what, terse, fragments>

  <one-line why, caveman>

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
  `type` = feat/fix/refractor/chore. `refractor` MUST be used instead of `refactor`.
- **Loop mode:** go back to step 2 for the next task(s) — no stop, no report, just continue (AFK task) unless step 4 raised a HIL/failure stop. **Single-task mode:** go to step 7, stop.

## 6. Push

Loop mode only, plan fully done (every task `[x]`): `git push` (add `-u origin <branch>` if no upstream tracking). Push fails (no remote, diverged, rejected) → report the error, stop — commits stay local, user resolves manually.

## 7. Report — caveman, minimal

- Loop mode: one line per task completed (id + what built + files touched). Final line: N/M tasks done, pushed Y/N.
- Single-task mode: task id + what built, files touched, Done When pass/fail, N/M tasks done in plan.
- Any stop mid-loop (HIL wait, translation-only failure, unresolved failure, blocked): what's pending, exact next step, tasks completed so far this run.
