---
name: tdd-implement
description: Pick lowest-index ready task from tasks/draft/, move it to tasks/in-progress/, implement it with strict TDD red-green-refactor (via the tdd skill), then move it to tasks/done/. Use when user says "tdd implement", "implement next task with TDD", or wants the next drafted task built test-first.
---

# TDD Implement

Pick next ready task from `tasks/draft/` → move to `tasks/in-progress/` → implement TDD → `tasks/done/`.

Sibling: `/to-implement` — same lifecycle, straight build instead of TDD.

## 1. Pick task

- Argument (task id `NNNN_SS` or path) → use that task, wherever it sits (`tasks/in-progress/` or `tasks/draft/`).
- No argument → check `tasks/in-progress/` FIRST. Task there → resume it: read task file, see which **Done When** boxes already ticked, diff code vs task to gauge real progress (boxes may lag code — verify, run existing tests), finish remaining work only. Multiple → lowest `NNNN_SS`. Task waiting ONLY on pending human step → report step, skip it, fall through to draft pick.
- `tasks/in-progress/` empty → lowest `NNNN_SS` in `tasks/draft/` whose **Depends** are ALL in `tasks/done/`.
- Tasks exist but none eligible → list what blocks each, stop.
- Both folders empty/missing → tell user, stop.

Draft pick → move file `tasks/draft/` → `tasks/in-progress/` (create folder if missing; `git mv` when tracked). Resumed task already there — no move. Then start.

## 2. Read context

- Task file fully. Then its **Refs** — PRD in `prd/in-progress/`, ADRs listed.
- **Depends** tasks in `tasks/done/` — esp. `Mode: reference` ones (modelling contracts).
- Explore code around the change: existing patterns, reusable components, theme, API/model conventions, test setup, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

## 3. Implement — TDD

Invoke `tdd` skill (Skill tool). Follow it exactly: vertical slices, one test → minimal impl → repeat, refactor only on GREEN.

Adaptations for task-driven run:

- Task file = approved plan. **Done When** boxes = behavior list to test. Don't block waiting for user plan approval.
- Tests through public interface only — survive refactor. Run via project's test wrapper/commands from CLAUDE.md.
- `Mode: reference` task (pure types/contracts, nothing executable) → no TDD loop; produce reference artifact, done.

Code rules (apply during GREEN + refactor):

- DRY, efficient, modern idiom for the stack. Smallest diff that satisfies task.
- UI tasks: reuse existing reusable components FIRST. New UI → small reusable components, not one blob. Logic out of templates into functions. Follow app theme + FSD layering. Minimal HTML/CSS. Good UX: loading/empty/error states, sensible spacing, accessibility.
- Respect ADRs. Task conflicts ADR → stop, ask user.

## 4. Verify

- Every **Done When** box must pass — check each, tick it in task file.
- Full project test suite + lint/format for touched area. All GREEN before moving on.

## 5. Close task

- `Human:` ≠ none and human step pending → task STAYS in `tasks/in-progress/`, report exact human step.
- Else move task file → `tasks/done/` (create folder if missing).

## 6. Close epic

No `NNNN_*` tasks left in `tasks/draft/` or `tasks/in-progress/`? → move `prd/in-progress/NNNN_<slug>.md` → `prd/done/` (create folder if missing). Else note remaining count.

## 7. Report — caveman, minimal

- Task id + one line what built. Files touched (paths only). Test count added/passing.
- Done When: each box pass/fail.
- Epic: N done / M total; PRD moved or stays.
- NO commit — user commits. No prose padding.
