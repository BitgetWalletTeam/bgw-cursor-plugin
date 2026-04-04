#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UPSTREAM_FILE="$REPO_ROOT/upstream.json"

if [ ! -f "$UPSTREAM_FILE" ]; then
  echo "ERROR: upstream.json not found at $UPSTREAM_FILE"
  exit 1
fi

command -v python3 >/dev/null || { echo "ERROR: python3 required"; exit 1; }

UPDATE_FLAG="${1:-}"
DRIFT_COUNT=0
TOTAL=0

echo "=== Upstream Drift Check ==="
echo "  Baseline: $UPSTREAM_FILE"
echo ""

python3 -c "
import json, sys
data = json.load(open('$UPSTREAM_FILE'))
for s in data['sources']:
    print(f\"{s['name']}|{s['repo']}|{s['branch']}|{s['pinnedCommit']}|{s['lastVerified']}\")
" | while IFS='|' read -r name repo branch pinned verified; do
  TOTAL=$((TOTAL + 1))
  current=$(git ls-remote --refs "$repo" "refs/heads/$branch" 2>/dev/null | awk '{print $1}')

  if [ -z "$current" ]; then
    echo "  ⚠ $name — could not fetch remote HEAD"
    continue
  fi

  if [ "$current" = "$pinned" ]; then
    echo "  ✓ $name — up to date (pinned: ${pinned:0:7})"
  else
    echo "  ✗ $name — DRIFT DETECTED"
    echo "    pinned:  ${pinned:0:7} (verified: $verified)"
    echo "    current: ${current:0:7}"
    echo "    compare: ${repo}/compare/${pinned:0:7}...${current:0:7}"
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
  fi
done

echo ""

if [ "$UPDATE_FLAG" = "--update" ]; then
  echo "Updating upstream.json with current HEAD commits..."

  python3 - "$UPSTREAM_FILE" <<'PY'
import json, subprocess, sys
from datetime import date

path = sys.argv[1]
data = json.load(open(path))

for source in data["sources"]:
    result = subprocess.run(
        ["git", "ls-remote", "--refs", source["repo"], f"refs/heads/{source['branch']}"],
        capture_output=True, text=True
    )
    if result.returncode == 0 and result.stdout.strip():
        new_sha = result.stdout.strip().split()[0]
        if new_sha != source["pinnedCommit"]:
            old = source["pinnedCommit"][:7]
            source["pinnedCommit"] = new_sha
            source["lastVerified"] = str(date.today())
            print(f"  ✓ {source['name']}: {old} → {new_sha[:7]}")
        else:
            print(f"  - {source['name']}: unchanged")
    else:
        print(f"  ⚠ {source['name']}: could not fetch")

data["lastVerified"] = str(date.today())
json.dump(data, open(path, "w"), indent=2)
print(f"\nupstream.json updated (lastVerified: {date.today()})")
PY
  echo ""
  echo "IMPORTANT: After updating, you must manually review the upstream"
  echo "changes and update the plugin content where needed. Use the"
  echo "'compare' URLs above to see what changed."
else
  echo "To update upstream.json with current commits:"
  echo "  bash scripts/check-upstream.sh --update"
  echo ""
  echo "After updating, review upstream changes and sync plugin content."
fi
