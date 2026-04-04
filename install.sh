#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
PLUGIN_NAME="bitget-wallet"
# Legacy manual registration (not loaded by current Claude Code); removed on install.
LEGACY_PLUGIN_ID="${PLUGIN_NAME}@local"
CLAUDE_MARKETPLACE_NAME="bitget-wallet-plugins"
CLAUDE_PLUGIN_INSTALL_ID="${PLUGIN_NAME}@${CLAUDE_MARKETPLACE_NAME}"

usage() {
  cat <<EOF
Bitget Wallet Plugin — Installer

Usage:
  bash install.sh              Install globally (all projects)
  bash install.sh --project    Install into current project only (symlinks)
  bash install.sh --uninstall  Remove global installation
  bash install.sh --help       Show this help

Global install (default):
  - Cursor: symlinks this repo into ~/.cursor/plugins/bitget-wallet
  - Claude Code: runs \`claude plugin marketplace add\` + \`claude plugin install\`
    (uses .claude-plugin/marketplace.json — the supported load path)

Project install (--project):
  Creates symlinks in the current working directory so the plugin is
  available only in this project. Useful when you don't want a global
  install or need a project-scoped override.

EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Remove obsolete bitget-wallet@local entries (older install.sh never loaded in CC)
# ---------------------------------------------------------------------------
remove_legacy_bitget_local_registration() {
  local claude_plugins="$HOME/.claude/plugins/installed_plugins.json"
  local claude_settings="$HOME/.claude/settings.json"
  python3 - "$claude_plugins" "$claude_settings" "$LEGACY_PLUGIN_ID" <<'PY'
import json, os, sys
ppath, spath, legacy = sys.argv[1], sys.argv[2], sys.argv[3]
for path, mode in ((ppath, "plugins"), (spath, "settings")):
    if not os.path.isfile(path):
        continue
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        continue
    changed = False
    if mode == "plugins":
        pl = data.get("plugins")
        if isinstance(pl, dict) and legacy in pl:
            pl.pop(legacy, None)
            changed = True
    else:
        ep = data.get("enabledPlugins")
        if isinstance(ep, dict) and legacy in ep:
            ep.pop(legacy, None)
            changed = True
    if changed:
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
PY
}

# ---------------------------------------------------------------------------
# Global install — ~/.cursor/plugins symlink + Claude Code marketplace install
# ---------------------------------------------------------------------------
install_global() {
  local target="$HOME/.cursor/plugins/$PLUGIN_NAME"

  echo "=== Bitget Wallet Plugin — Global Install ==="
  echo "  Source: $REPO_ROOT"
  echo ""

  # 1. Link plugin directory (Cursor)
  echo "[1/2] Linking plugin into ~/.cursor/plugins/ ..."
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

  # 2. Claude Code — bundled marketplace (.claude-plugin/marketplace.json)
  echo "[2/2] Claude Code plugin (marketplace) ..."
  if command -v claude >/dev/null 2>&1; then
    mkdir -p "$HOME/.claude/plugins"
    local mp_out
    mp_out="$(claude plugin marketplace add "$REPO_ROOT" 2>&1)" || true
    if echo "$mp_out" | grep -q "Successfully added marketplace"; then
      echo "  ✓ Registered marketplace $CLAUDE_MARKETPLACE_NAME"
    elif echo "$mp_out" | grep -qi "already installed"; then
      echo "  ✓ Marketplace $CLAUDE_MARKETPLACE_NAME already registered"
    else
      echo "  ⚠ marketplace add — check output:"
      echo "$mp_out" | sed 's/^/    /'
    fi
    if claude plugin install "$CLAUDE_PLUGIN_INSTALL_ID" 2>&1; then
      echo "  ✓ Installed $CLAUDE_PLUGIN_INSTALL_ID"
    else
      echo "  ⚠ Run manually: claude plugin install $CLAUDE_PLUGIN_INSTALL_ID"
    fi
    remove_legacy_bitget_local_registration
  else
    echo "  skipped (claude CLI not in PATH)"
    echo ""
    echo "  For Claude Code, run after installing the claude CLI:"
    echo "    claude plugin marketplace add \"$REPO_ROOT\""
    echo "    claude plugin install $CLAUDE_PLUGIN_INSTALL_ID"
  fi

  echo ""
  echo "=== Installation Complete ==="
  echo ""
  echo "Next steps:"
  echo "  1. Restart Cursor (Cmd+Shift+P → 'Reload Window' or quit & reopen)"
  echo "  2. Restart Claude Code (quit all sessions) so plugins reload"
  echo "  3. Verify Claude:  claude plugin list  (expect $CLAUDE_PLUGIN_INSTALL_ID)"
  echo "  4. In Cursor Settings → Features, enable 'Include third-party Plugins'"
  echo "     (if the toggle exists in your version)"
  echo ""
  echo "To update later:  cd $REPO_ROOT && git pull && bash install.sh"
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

  if command -v claude >/dev/null 2>&1; then
    claude plugin uninstall "$CLAUDE_PLUGIN_INSTALL_ID" 2>/dev/null || true
    claude plugin marketplace remove "$CLAUDE_MARKETPLACE_NAME" 2>/dev/null || true
    echo "  ✓ Claude Code: removed $CLAUDE_PLUGIN_INSTALL_ID / marketplace (if present)"
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
    echo "  ✓ Removed $target"
  else
    echo "  - $target not found (already removed)"
  fi

  if [ -f "$claude_plugins" ]; then
    python3 - "$claude_plugins" "$CLAUDE_PLUGIN_INSTALL_ID" "$LEGACY_PLUGIN_ID" <<'PY'
import json, os, sys
path, pid1, pid2 = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(open(path))
except Exception:
    exit(0)
pl = data.get("plugins")
if isinstance(pl, dict):
    pl.pop(pid1, None)
    pl.pop(pid2, None)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY
    echo "  ✓ Cleaned installed_plugins.json (if entries remained)"
  fi

  if [ -f "$claude_settings" ]; then
    python3 - "$claude_settings" "$CLAUDE_PLUGIN_INSTALL_ID" "$LEGACY_PLUGIN_ID" <<'PY'
import json, os, sys
path, pid1, pid2 = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(open(path))
except Exception:
    exit(0)
ep = data.get("enabledPlugins")
if isinstance(ep, dict):
    ep.pop(pid1, None)
    ep.pop(pid2, None)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY
    echo "  ✓ Cleaned enabledPlugins (if entries remained)"
  fi

  echo ""
  echo "Done. Restart Cursor and Claude Code to complete removal."
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
