---
name: start
description: Bootstrap docs-driven project scaffolding on a new or empty project. Asks for frontend/backend folder paths, inspects their stacks, then writes a minimal CLAUDE.md (structure, commands, FE-BE relationship) and creates docs/prd, docs/adr, docs/tasks folders with an initial 000_architecture.md ADR. Use when user runs /start or asks to initialize project documentation structure.
disable-model-invocation: true
---

# Start — Project Docs Bootstrap

Initializes a docs-driven workflow in the current project. All generated docs must be
minimal and dual-audience: efficient for AI agents to load as context, readable for humans.

## Workflow

1. **Ask for folders** — single question covering both (AskUserQuestion or plain prompt):
   - Frontend folder path (or "none")
   - Backend folder path (or "none")
   Accept paths relative to project root. Verify each path exists before proceeding.

2. **Inspect each folder** (skip if "none" or empty):
   - Detect stack from manifests: `package.json` (framework deps + scripts),
     `requirements.txt` / `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, etc.
   - Extract: language, framework, install/dev/test/build commands, dev port
     (from scripts, config files, `.env.example`).
   - Record only what files prove. Never invent commands. Unknowns → mark `TBD`.

3. **Establish the FE ↔ BE relationship**:
   - Frontend side: API base URL from env files, proxy config, fetch/axios setup.
   - Backend side: port, API prefix, CORS config from settings/server entry.
   - Record as: `FE (:port) → HTTP → BE (:port)/prefix`, plus auth method if visible.
   - Nothing detectable → ask the user one focused question, or mark `TBD`.

4. **Create structure**:
   ```
   CLAUDE.md
   docs/
   ├── prd/      ← product requirement docs   (001_name.md ...)
   ├── adr/      ← architecture decision records (000_architecture.md ...)
   └── tasks/    ← task breakdowns            (001_name.md ...)
   ```

5. **Write docs** using templates in [TEMPLATES.md](TEMPLATES.md):
   - `CLAUDE.md` — fill detected facts only.
   - `docs/adr/000_architecture.md` — initial architecture ADR.
   - One short `README.md` per docs folder defining naming + section format.

6. **Report** — print the created tree and list every `TBD` left for the user to fill.

## Rules

- Intended for empty/new projects. If `CLAUDE.md` or `docs/` already exists,
  show what would change and confirm with the user before overwriting.
- Minimal output: tables and short lines, zero prose padding. Every line must
  help an agent (or human) make a decision; delete lines that don't.
- Numbering: ADRs start at `000_`; PRDs and tasks start at `001_`. Zero-padded, underscore after number.
- Date in ADRs: today's actual date, ISO format (YYYY-MM-DD).
