#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
PLUGIN_NAME="bitget-wallet"
PLUGIN_ID="${PLUGIN_NAME}@local"

usage() {
  cat <<EOF
Bitget Wallet Plugin — Installer

Usage:
  bash install.sh              Install globally (all projects)
  bash install.sh --project    Install into current project only (symlinks)
  bash install.sh --uninstall  Remove global installation
  bash install.sh --help       Show this help

Global install (default):
  Registers the plugin in ~/.cursor/plugins/ so Cursor loads it in every
  project you open. This is the recommended approach before the plugin is
  listed on the Cursor marketplace.

Project install (--project):
  Creates symlinks in the current working directory so the plugin is
  available only in this project. Useful when you don't want a global
  install or need a project-scoped override.

EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Global install — register in ~/.cursor/plugins + ~/.claude config
# ---------------------------------------------------------------------------
install_global() {
  local target="$HOME/.cursor/plugins/$PLUGIN_NAME"
  local claude_dir="$HOME/.claude"
  local claude_plugins="$claude_dir/plugins/installed_plugins.json"
  local claude_settings="$claude_dir/settings.json"

  echo "=== Bitget Wallet Plugin — Global Install ==="
  echo "  Source: $REPO_ROOT"
  echo ""

  # 1. Link plugin directory
  echo "[1/3] Linking plugin into ~/.cursor/plugins/ ..."
  mkdir -p "$HOME/.cursor/plugins"
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    echo "  WARNING: $target exists and is not a symlink."
    echo "  Removing old copy..."
    rm -rf "$target"
  fi
  ln -s "$REPO_ROOT" "$target"
  echo "  ✓ $target → $REPO_ROOT"

  # 2. Register in installed_plugins.json
  echo "[2/3] Registering plugin..."
  mkdir -p "$claude_dir/plugins"

  python3 - "$claude_plugins" "$PLUGIN_ID" "$target" <<'PY'
import json, os, sys
path, pid, ipath = sys.argv[1], sys.argv[2], sys.argv[3]
data = {}
if os.path.exists(path):
    try:
        data = json.load(open(path))
    except (json.JSONDecodeError, IOError):
        data = {}
plugins = data.setdefault("plugins", {})
entries = [e for e in plugins.get(pid, [])
           if not (isinstance(e, dict) and e.get("scope") == "user")]
entries.insert(0, {"scope": "user", "installPath": ipath})
plugins[pid] = entries
json.dump(data, open(path, "w"), indent=2)
PY
  echo "  ✓ Registered in $claude_plugins"

  # 3. Enable in settings.json
  echo "[3/3] Enabling plugin..."

  python3 - "$claude_settings" "$PLUGIN_ID" <<'PY'
import json, os, sys
path, pid = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        data = json.load(open(path))
    except (json.JSONDecodeError, IOError):
        data = {}
data.setdefault("enabledPlugins", {})[pid] = True
json.dump(data, open(path, "w"), indent=2)
PY
  echo "  ✓ Enabled in $claude_settings"

  echo ""
  echo "=== Installation Complete ==="
  echo ""
  echo "Next steps:"
  echo "  1. Restart Cursor (Cmd+Shift+P → 'Reload Window' or quit & reopen)"
  echo "  2. In Cursor Settings → Features, enable 'Include third-party Plugins'"
  echo "     (if the toggle exists in your version)"
  echo "  3. The plugin is now available in ALL your projects"
  echo ""
  echo "To update later:  cd $REPO_ROOT && git pull"
  echo "To uninstall:     bash $REPO_ROOT/install.sh --uninstall"
}

# ---------------------------------------------------------------------------
# Per-project install — symlinks at workspace root
# ---------------------------------------------------------------------------
install_project() {
  local project_dir
  project_dir="$(pwd)"

  if [ "$project_dir" = "$REPO_ROOT" ]; then
    echo "ERROR: You are inside the plugin repo itself."
    echo "  cd into your target project first, then run:"
    echo "  bash $REPO_ROOT/install.sh --project"
    exit 1
  fi

  echo "=== Bitget Wallet Plugin — Project Install ==="
  echo "  Source:  $REPO_ROOT"
  echo "  Target:  $project_dir"
  echo ""

  local items=(".cursor-plugin" ".claude-plugin" "skills" "rules" "agents"
               ".mcp.json" "CLAUDE.md" "assets" "scripts" "requirements.txt")
  local linked=()
  local skipped=()

  for item in "${items[@]}"; do
    local target="$project_dir/$item"
    local source="$REPO_ROOT/$item"

    if [ ! -e "$source" ] && [ ! -L "$source" ]; then
      continue
    fi

    if [ -L "$target" ]; then
      rm "$target"
      ln -s "$source" "$target"
      linked+=("$item (updated)")
    elif [ -e "$target" ]; then
      skipped+=("$item (already exists — skipped)")
    else
      ln -s "$source" "$target"
      linked+=("$item")
    fi
  done

  echo "Linked:"
  for l in "${linked[@]}"; do echo "  ✓ $l"; done

  if [ ${#skipped[@]} -gt 0 ]; then
    echo ""
    echo "Skipped (already exist — not symlinks):"
    for s in "${skipped[@]}"; do echo "  ⚠ $s"; done
  fi

  echo ""
  echo "Add these to your project's .gitignore:"
  echo ""
  echo "  # Bitget Wallet Plugin (symlinks)"
  for item in "${items[@]}"; do
    if [ -L "$project_dir/$item" ]; then
      echo "  $item"
    fi
  done

  echo ""
  echo "=== Done ==="
  echo "  Open this project in Cursor. The plugin loads automatically."
  echo "  To remove: bash $REPO_ROOT/install.sh --uninstall-project"
}

# ---------------------------------------------------------------------------
# Uninstall — global
# ---------------------------------------------------------------------------
uninstall_global() {
  local target="$HOME/.cursor/plugins/$PLUGIN_NAME"
  local claude_plugins="$HOME/.claude/plugins/installed_plugins.json"
  local claude_settings="$HOME/.claude/settings.json"

  echo "=== Bitget Wallet Plugin — Uninstall (Global) ==="

  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
    echo "  ✓ Removed $target"
  else
    echo "  - $target not found (already removed)"
  fi

  if [ -f "$claude_plugins" ]; then
    python3 - "$claude_plugins" "$PLUGIN_ID" <<'PY'
import json, os, sys
path, pid = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except:
    exit(0)
data.get("plugins", {}).pop(pid, None)
json.dump(data, open(path, "w"), indent=2)
PY
    echo "  ✓ Deregistered from installed_plugins.json"
  fi

  if [ -f "$claude_settings" ]; then
    python3 - "$claude_settings" "$PLUGIN_ID" <<'PY'
import json, os, sys
path, pid = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except:
    exit(0)
data.get("enabledPlugins", {}).pop(pid, None)
json.dump(data, open(path, "w"), indent=2)
PY
    echo "  ✓ Disabled in settings.json"
  fi

  echo ""
  echo "Done. Restart Cursor to complete removal."
}

# ---------------------------------------------------------------------------
# Uninstall — per-project (remove symlinks from current directory)
# ---------------------------------------------------------------------------
uninstall_project() {
  local project_dir
  project_dir="$(pwd)"

  echo "=== Bitget Wallet Plugin — Uninstall (Project) ==="
  echo "  Target: $project_dir"
  echo ""

  local items=(".cursor-plugin" ".claude-plugin" "skills" "rules" "agents"
               ".mcp.json" "CLAUDE.md" "assets" "scripts" "requirements.txt")

  for item in "${items[@]}"; do
    local target="$project_dir/$item"
    if [ -L "$target" ]; then
      local link_target
      link_target="$(readlink "$target")"
      if [[ "$link_target" == *"$PLUGIN_NAME"* ]] || [[ "$link_target" == "$REPO_ROOT"* ]]; then
        rm "$target"
        echo "  ✓ Removed symlink: $item"
      fi
    fi
  done

  echo ""
  echo "Done. You can also remove the .gitignore entries added during install."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
case "${1:-}" in
  --help|-h)     usage ;;
  --project)     install_project ;;
  --uninstall)   uninstall_global ;;
  --uninstall-project) uninstall_project ;;
  "")            install_global ;;
  *)
    echo "Unknown option: $1"
    echo "Run 'bash install.sh --help' for usage."
    exit 1
    ;;
esac
