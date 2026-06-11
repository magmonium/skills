---
name: to-implement
description: Pick lowest-index ready task from tasks/draft/, move it to tasks/in-progress/, implement it straight following existing codebase patterns, then move it to tasks/done/ — and move the epic's PRD from prd/in-progress/ to prd/done/ when all its tasks finish. Use when user says "to implement", "implement next task", or wants the next drafted task built directly (no TDD).
---

# To Implement

Pick next ready task from `tasks/draft/` → move to `tasks/in-progress/` → implement → `tasks/done/` → all epic tasks done → PRD to `prd/done/`.

Sibling: `/tdd-implement` — same lifecycle, TDD red-green-refactor instead of straight build.

## 1. Pick task

- Argument (task id `NNNN_SS` or path) → use that task.
- No argument → lowest `NNNN_SS` in `tasks/draft/` whose **Depends** are ALL in `tasks/done/`.
- Tasks exist but none eligible → list what blocks each, stop.
- Folder empty/missing → tell user, stop.

Move picked file `tasks/draft/` → `tasks/in-progress/` (create folder if missing; `git mv` when tracked). Then start.

## 2. Read context

- Task file fully. Then its **Refs** — PRD in `prd/in-progress/`, ADRs listed.
- **Depends** tasks in `tasks/done/` — esp. `Mode: reference` ones (modelling contracts).
- Explore code around the change: existing patterns, reusable components, theme, API/model conventions, project CLAUDE.md. Match what exists — no new pattern when one already covers it.

## 3. Implement

Straight build. No test-first ceremony — add tests only where project convention expects them.

Rules:

- DRY, efficient, modern idiom for the stack. Smallest diff that satisfies task.
- Follow per-type rules in task file (mock data for frontend, contract from modelling task, etc.).
- UI tasks: reuse existing reusable components FIRST. New UI → small reusable components, not one blob. Logic out of templates into functions. Follow app theme + FSD layering. Minimal HTML/CSS. Good UX: loading/empty/error states, sensible spacing, accessibility.
- `Mode: reference` task → produce reference artifact (types/interfaces/contract), nothing more.
- Respect ADRs. Task conflicts ADR → stop, ask user.

## 4. Verify

- Every **Done When** box must pass — check each, tick it in task file.
- Run project test suite + lint/format for touched area (use project's wrapper/commands from CLAUDE.md). Fail → fix before moving on.

## 5. Close task

- `Human:` ≠ none and human step pending → task STAYS in `tasks/in-progress/`, report exact human step.
- Else move task file → `tasks/done/` (create folder if missing).

## 6. Close epic

No `NNNN_*` tasks left in `tasks/draft/` or `tasks/in-progress/`? → move `prd/in-progress/NNNN_<slug>.md` → `prd/done/` (create folder if missing). Else note remaining count.

## 7. Report — caveman, minimal

- Task id + one line what built. Files touched (paths only).
- Done When: each box pass/fail.
- Epic: N done / M total; PRD moved or stays.
- NO commit — user commits. No prose padding.
