# Magmonium Skills

Claude Code plugin marketplace.

## Install

```
/plugin marketplace add magmonium/skills
/plugin install workflow-skills@magmonium-skills
/plugin install magmonium-skills@magmonium-skills
```

## Plugins

### workflow-skills — PRD-driven dev workflow

Lifecycle: `grill-to-prd` → `to-tasks` → `to-implement` / `tdd-implement` → `to-review`.

| Skill | Job |
|-------|-----|
| `start` | Bootstrap docs-driven scaffolding (CLAUDE.md, docs/prd, docs/adr, docs/tasks) on new project |
| `grill-to-prd` | Interview relentlessly, write caveman PRD to `prd/draft/NNNN_<slug>.md` |
| `to-tasks` | Slice next PRD into typed task files `tasks/draft/NNNN_SS_<type>_<desc>.md`, PRD → `prd/in-progress/` |
| `to-implement` | Pick lowest ready task, build straight, task → `tasks/done/`; epic done → PRD → `prd/done/` |
| `tdd-implement` | Same lifecycle, strict red-green-refactor via `tdd` skill |
| `tdd` | Test-driven development discipline (used by `tdd-implement`) |
| `to-review` | Verify highest done PRD against real code, SEC/ARCH/DRY audit, gap/refactor tasks reopen PRD |

### magmonium-skills — NX Angular monorepo

| Skill | Job |
|-------|-----|
| `mm-app` | Scaffold/configure Magmonium WC app (module federation, nav widgets, providers) |
| `one-ui` | `@magmonium/one` UI components |
| `translate` | i18n workflow — missing keys → YAML assets |

## Syncing

Source of truth: `~/.claude/skills/` on dev machine. Working clone lives at `~/.magmonium/skills` (outside `~/Documents` — macOS TCC blocks launchd there). `./sync.sh` copies tracked skills into plugin folders, bumps patch version of changed plugins, commits, pushes.

launchd agent `com.magmonium.skills-sync` (`~/Library/LaunchAgents/`) runs sync automatically: on watched skill-file change + every 30 min fallback. Skills symlinked into `~/Documents` (e.g. `tdd`) are TCC-unreadable under launchd — they sync only on manual terminal runs.

```
~/.magmonium/skills/sync.sh      # manual sync
launchctl unload ~/Library/LaunchAgents/com.magmonium.skills-sync.plist   # stop auto-sync
```
