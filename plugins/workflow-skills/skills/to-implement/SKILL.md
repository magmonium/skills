---
name: to-implement
description: Pick lowest-index ready task from tasks/draft/, move it to tasks/in-progress/, implement it straight following existing codebase patterns, then move it to tasks/done/. Use when user says "to implement", "implement next task", or wants the next drafted task built directly (no TDD).
---

# To Implement

Pick next ready task from `tasks/draft/` → move to `tasks/in-progress/` → implement → `tasks/done/` → all epic tasks done → PRD to `prd/done/`.

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

## 6. Feature status

No `NNNN_*` tasks left in `tasks/draft/` or `tasks/in-progress/` for this NNNN → feature fully done, ready for `/to-review`. Else note remaining count.

## 7. Report — caveman, minimal

- Task id + one line what built. Files touched (paths only).
- Done When: each box pass/fail.
- Feature: N done / M total tasks for this NNNN.
- NO commit — user commits. No prose padding.
