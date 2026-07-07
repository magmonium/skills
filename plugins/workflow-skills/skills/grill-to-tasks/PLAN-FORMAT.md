# Plan Format

File: `tasks/NNNN_<kebab-desc>_plan.md` — one flat file per feature. No folder, no separate task files.

- `NNNN` — feature index, 4 digits.
- `<kebab-desc>` — short kebab-case feature name.

All prose caveman. Keep file SMALL — agent reads the whole thing in seconds.

## File structure

````md
# NNNN — <Feature Title>

## Problem

What hurts. One precise paragraph.

## Architecture Decisions

Modules touched or created. Interfaces defined (inputs/outputs/contracts).
Seams introduced. Schema changes. API shapes. No file paths. No code snippets
(exception: prototype snippet encoding a decision more precisely than prose).

## Testing

What makes a good test. Which modules get tests. Prior art in codebase.

## Out of Scope

What this plan explicitly does NOT cover.

## Tasks

### [ ] NNNN_SS — <Task Title>

- **Type:** frontend | backend | integration | migration | one-ui
- **Mode:** implement | reference
- **Human:** none | <what human must do>
- **Depends:** none | NNNN_SS, NNNN_SS
- **Refs:** docs/adr/XXXX (if any) — omit line if none

**Context:** 2–4 lines, caveman. What hurts + what fixes it, distilled from the grill —
just the slice relevant to THIS task. No PRD to point at; this is the only context the
agent gets.

**What:** 2–5 lines. What to build, where it lives, which contract/reference task it
follows.

**Done When:**
- [ ] Observable outcome 1
- [ ] Observable outcome 2
- [ ] User runs translation:fix / asset compile / build / test, confirms pass

### [ ] NNNN_SS — <next task>
...
````

## Field rules

- **Task checkbox** (`[ ]` on the `###` heading) — the task's own status. Ticked only when every Done-When box (incl. human gate) is ticked. This is what `/to-implement`, `/tdd-implement`, `/to-review` scan to find work.
- **Mode: reference** — task output consumed by other tasks. Says so in What.
- **Human:** name the exact human step (approve design, provide API key, manual QA on device). `none` when agent finishes alone.
- **Depends:** task IDs only (`NNNN_SS`). Blocked task starts after blockers' checkboxes are ticked. Frontend ∥ backend — no dependency between them. Parallel tasks (same SS) note each other: `parallel: NNNN_SS`.
- **Refs:** ADRs only, when task leans on one. Omit the line entirely if no ADR applies.
- **Context:** carries what a PRD would have — problem/solution/decisions for this slice. Written fresh per task from the grill session, not copy-pasted verbatim across tasks.
- **Task order = dependency order.** Top to bottom in `## Tasks` is the build order. No SS-derived sorting needed elsewhere — position in the file IS the order. `/to-review` appends new tasks at the bottom, continuing the SS sequence.

## Per-type What must include

- `frontend` — screen/components, MOCK data shape, which One UI components reused, app theme, assets needed (icons/images — create in this task), minimal HTML/CSS, small reusable components, logic in separate functions, FSD layering. Zero API calls. Translation: agent does NOT run `/translate` or `translation:fix` itself — see Done When rules.
- `backend` — endpoints/logic/DB changes, contract (request/response shapes) integration task binds to.
- `integration` — which frontend task's mocks swap for which backend task's endpoints, loading/error states, feature works end-to-end.
- `migration` — review scope (files/modules earlier tasks touched), checks: architecture deviation (FSD, module boundaries), DRY violations, security issues, run `/fe-review` skill on FE delta. Fix/migrate what found. Only created when implementation warrants — skip small/clean work.
- `one-ui` — component API (inputs/outputs), where it lands in One UI library, demo/story if library convention, which frontend task consumes it. Only created after user said yes. PURELY presentational: UI/UX + aesthetics only — zero business logic, no API calls, no state management, no domain rules. Data in via inputs, events out via outputs; consuming frontend task owns all logic.

## Done When rules

- External behavior only — no implementation detail.
- Each box checkable by agent or named human.
- 2–5 boxes. More → task too big, split it.
- Last box ALWAYS the human gate (see exact wording above). Agent NEVER runs translation:fix, asset compile, build, or test itself. Skip only when `Mode: reference` produces no code. Gate box doesn't count toward 2–5.
- Human-in-loop gate: agent finishes other boxes → ticks them → lists exact commands (from CLAUDE.md/package.json/repo scripts, never invented) → stops, waits. User OK → tick gate box AND the task's own heading checkbox, commit. User says broken → fix, re-list, wait again. Loop till confirmed.
