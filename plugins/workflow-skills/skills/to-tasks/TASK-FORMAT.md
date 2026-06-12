# Task Format

File: `tasks/draft/NNNN_SS_<type>_<kebab-desc>.md`

- `NNNN` — PRD index, 4 digits (matches PRD file).
- `SS` — sequence, 2 digits, dependency order (01 first).
- `<type>` — modelling | backend | frontend | migration | integration | assets | translation.
- `<kebab-desc>` — short kebab-case task name.

Example: `0003_01_modelling_app-deploy-status.md`, `0003_04_frontend_deploy-status-card.md`

All prose caveman. Section order fixed — agents rely on it. Keep whole file SMALL — agent reads in seconds.

````md
# NNNN_SS — <Title>

- **Type:** frontend
- **Mode:** implement | reference
- **Human:** none | <what human must do>
- **Depends:** none | NNNN_SS, NNNN_SS
- **Refs:** prd/in-progress/NNNN_<slug>.md, docs/adr/XXXX (if any)

## What

2–5 lines. What to build, where it lives, which contract/reference task it follows.

## Done When

- [ ] Observable outcome 1
- [ ] Observable outcome 2
- [ ] Lint, build, test pass — project's configured commands
````

## Field rules

- **Mode: reference** — task output consumed by other tasks (e.g. modelling types → swagger/interface). Says so in What.
- **Human:** name the exact human step (approve design, provide API key, manual QA on device). `none` when agent finishes alone.
- **Depends:** task IDs only (`NNNN_SS`). Blocked task starts after blockers done.
- **Refs:** always main PRD; ADRs only when task leans on one.

## Per-type What must include

- `modelling` — entities, fields, types for FE+BE; note swagger/interface generated from this.
- `backend` — endpoints/logic, which modelling task defines contract.
- `frontend` / `migration` — screen/component, MOCK data, reuse which existing components, app theme, minimal HTML/CSS, small reusable components, logic in separate functions, FSD layering. `frontend` = new screen; `migration` = change existing.
- `integration` — which frontend task's mocks swap for which backend task's real API.
- `assets` — which assets, format, where they land.
- `translation` — which screens' strings, i18n key names, asset file location.

## Done When rules

- External behavior only — no implementation detail.
- Each box checkable by agent or named human.
- 2–5 boxes. More → task too big, split it.
