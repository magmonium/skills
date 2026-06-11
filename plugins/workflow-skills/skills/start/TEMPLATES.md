# Templates

Fill `<placeholders>` with detected facts. Leave `TBD` where nothing was detected.
Delete rows/lines that don't apply (e.g. no frontend → drop FE column).

## CLAUDE.md

```md
# <Project Name>

<one-line purpose>

## Structure

| Folder | Role | Stack |
|--------|------|-------|
| `<fe>/` | frontend | <framework + language> |
| `<be>/` | backend | <framework + language> |
| `docs/` | project state — PRDs, ADRs, tasks | markdown |

## Commands

| Action | Frontend (`<fe>/`) | Backend (`<be>/`) |
|--------|--------------------|--------------------|
| install | `<cmd>` | `<cmd>` |
| dev | `<cmd>` | `<cmd>` |
| test | `<cmd>` | `<cmd>` |
| build | `<cmd>` | `<cmd>` |

## Frontend ↔ Backend

- FE dev server: `http://localhost:<port>`
- BE API: `http://localhost:<port><prefix>`
- FE calls BE via <fetch/axios/proxy>; base URL from `<env var or config file>`
- Auth: <method or TBD>

## Docs Workflow

Project state lives in `docs/` — read before changing code, update after deciding.

- Requirements → `docs/prd/NNN_name.md`
- Decisions → `docs/adr/NNN_name.md` (baseline: `000_architecture.md`)
- Work breakdown → `docs/tasks/NNN_name.md`
- New architectural decision made during any task → record it as a new ADR.
```

## docs/adr/000_architecture.md

```md
# 000 — Base Architecture

- Status: accepted
- Date: <YYYY-MM-DD>

## Context

New project. <one-line goal>

## Decision

- Frontend: <framework> in `<fe>/`, dev server on `:<port>`
- Backend: <framework> in `<be>/`, API on `:<port>` at `<prefix>`
- Communication: <REST/GraphQL> over HTTP; FE base URL via <mechanism>
- Data store: <db or TBD>
- Project state managed in `docs/` (prd, adr, tasks)

## Consequences

- Architecture changes recorded as new ADRs (`001_...`), never by editing this file.
- Agents derive project context from `CLAUDE.md` + this file.
```

## docs/adr/README.md

```md
# ADRs — Architecture Decision Records

One decision per file: `NNN_short-name.md`. `000` = base architecture.
Sections: Status, Date, Context, Decision, Consequences.
Never edit an accepted ADR — supersede it with a new one that references the old.
```

## docs/prd/README.md

```md
# PRDs — Product Requirement Docs

One feature per file: `NNN_short-name.md` (start at 001).
Sections: Problem, Goals, Non-goals, Requirements, Open questions.
Keep each requirement testable; link related ADRs/tasks.
```

## docs/tasks/README.md

```md
# Tasks

One work unit per file: `NNN_short-name.md` (start at 001), linked to its PRD/ADR.
Sections: Goal, Steps (checklist), Done criteria.
Check off steps as completed — this is the live state of work.
```
