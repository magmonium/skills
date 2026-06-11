#!/usr/bin/env bash
# Sync local skills (~/.claude/skills) into this repo, bump plugin version, commit, push.
# Run manually or via launchd watcher (com.magmonium.skills-sync).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HOME/.claude/skills"

# plugin name -> skills it tracks
WORKFLOW_SKILLS=(grill-to-prd to-tasks to-implement tdd-implement to-review tdd start)
MAGMONIUM_SKILLS=(mm-app translate)

sync_plugin() {
  local plugin="$1"; shift
  local skills=("$@")
  local dest="$REPO_DIR/plugins/$plugin/skills"
  for s in "${skills[@]}"; do
    if [ -d "$SRC/$s" ]; then
      rsync -a --delete "$SRC/$s/" "$dest/$s/"
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

cd "$REPO_DIR"

bumped=()
for plugin in workflow-skills magmonium-skills; do
  if ! git diff --quiet -- "plugins/$plugin/skills" || \
     [ -n "$(git status --porcelain -- "plugins/$plugin/skills")" ]; then
    version=$(bump_patch "plugins/$plugin/.claude-plugin/plugin.json")
    bumped+=("$plugin@$version")
  fi
done

git add -A
if git diff --cached --quiet; then
  echo "skills in sync, nothing to push"
  exit 0
fi

git commit -m "chore: sync skills ${bumped[*]:-}"
git push
echo "pushed: ${bumped[*]:-manifest-only change}"
