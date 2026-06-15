# Task Format

File: `tasks/draft/NNNN_SS_<type>_<kebab-desc>.md`

- `NNNN` — feature index, 4 digits (shared by all tasks of this feature).
- `SS` — sequence, 2 digits, dependency order (01 first).
- `<type>` — frontend | backend | integration | migration | one-ui.
- `<kebab-desc>` — short kebab-case task name.

Example: `0007_01_backend_deploy-status-api.md`, `0007_01_frontend_deploy-status-screen.md` (same SS = parallel), `0007_02_integration_deploy-status-wire.md`

All prose caveman. Section order fixed — agents rely on it. Keep whole file SMALL — agent reads in seconds.

````md
# NNNN_SS — <Title>

- **Type:** frontend
- **Mode:** implement | reference
- **Human:** none | <what human must do>
- **Depends:** none | NNNN_SS, NNNN_SS
- **Refs:** docs/adr/XXXX (if any) — omit line if none

## Context

2–4 lines, caveman. What hurts + what fixes it, distilled from the grill — just the slice relevant to THIS task. No PRD to point at; this is the only context the agent gets.

## What

2–5 lines. What to build, where it lives, which contract/reference task it follows.

## Done When

- [ ] Observable outcome 1
- [ ] Observable outcome 2
- [ ] User runs translation:fix / asset compile / build / test, confirms pass
````

## Field rules

- **Mode: reference** — task output consumed by other tasks. Says so in What.
- **Human:** name the exact human step (approve design, provide API key, manual QA on device). `none` when agent finishes alone.
- **Depends:** task IDs only (`NNNN_SS`). Blocked task starts after blockers done. Frontend ∥ backend — no dependency between them.
- **Refs:** ADRs only, when task leans on one. No PRD — omit the line entirely if no ADR applies.
- **Context:** carries what a PRD would have — problem/solution/decisions for this slice. Written fresh per task from the grill session, not copy-pasted verbatim across tasks.

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
- Last box ALWAYS: "User runs verification (translation:fix / asset compile / build / test per project commands) and confirms result." Agent does NOT run translation:fix, asset compilation, build, or test itself. Skip only when `Mode: reference` produces no code. Gate box doesn't count toward 2–5.
- After implementing all other boxes, agent lists exact commands user must run (from project CLAUDE.md / package.json / repo scripts — never invented), then stops and waits. User confirms OK → tick gate box, commit per repo norm. User reports broken → agent fixes, lists steps again, waits again — repeat until user confirms.
