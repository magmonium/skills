#!/usr/bin/env bash
# Sync local skills (~/.claude/skills) and agents (~/.claude/agents) into this repo,
# bump plugin version, commit, push.
# Run manually or via launchd watcher (com.magmonium.skills-sync).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SKILLS="$HOME/.claude/skills"
SRC_AGENTS="$HOME/.claude/agents"

# plugin name -> skills it tracks
WORKFLOW_SKILLS=(grill-to-prd to-tasks to-implement tdd-implement to-review tdd start)
MAGMONIUM_SKILLS=(mm-app translate)

# plugin name -> agents it tracks (flat .md files, not subdirs)
MAGMONIUM_AGENTS=(angular-fsd-expert)

sync_plugin() {
  local plugin="$1"; shift
  local skills=("$@")
  local dest="$REPO_DIR/plugins/$plugin/skills"
  for s in "${skills[@]}"; do
    if [ -d "$SRC_SKILLS/$s" ]; then
      # symlinked skills pointing into ~/Documents are TCC-blocked under
      # launchd — skip there, manual terminal runs still sync them
      if ! rsync -aL --delete "$SRC_SKILLS/$s/" "$dest/$s/" 2>/dev/null; then
        echo "skip $s (source unreadable — run ./sync.sh from terminal to sync it)"
      fi
    fi
  done
}

sync_agents() {
  local plugin="$1"; shift
  local agents=("$@")
  local dest="$REPO_DIR/plugins/$plugin/agents"
  mkdir -p "$dest"
  for a in "${agents[@]}"; do
    local src_file="$SRC_AGENTS/$a.md"
    if [ -f "$src_file" ]; then
      if ! rsync -aL "$src_file" "$dest/$a.md" 2>/dev/null; then
        echo "skip agent $a (source unreadable — run ./sync.sh from terminal to sync it)"
      fi
    fi
  done
}

bump_patch() {
  local manifest="$1"
  python3 - "$manifest" <<'EOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
major, minor, patch = data["version"].split(".")
data["version"] = f"{major}.{minor}.{int(patch) + 1}"
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(data["version"])
EOF
}

sync_plugin workflow-skills "${WORKFLOW_SKILLS[@]}"
sync_plugin magmonium-skills "${MAGMONIUM_SKILLS[@]}"
sync_agents magmonium-skills "${MAGMONIUM_AGENTS[@]}"

cd "$REPO_DIR"

bumped=()
for plugin in workflow-skills magmonium-skills; do
  if ! git diff --quiet -- "plugins/$plugin" || \
     [ -n "$(git status --porcelain -- "plugins/$plugin")" ]; then
    version=$(bump_patch "plugins/$plugin/.claude-plugin/plugin.json")
    bumped+=("$plugin@$version")
  fi
done

git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore: sync skills+agents${bumped[*]:+ ${bumped[*]}}"
fi

# push anything unpushed — covers commits whose push failed earlier
if [ -n "$(git log --oneline @{u}..HEAD 2>/dev/null)" ]; then
  git push
  echo "pushed: ${bumped[*]:-pending commits}"
else
  echo "skills+agents in sync, nothing to push"
fi
