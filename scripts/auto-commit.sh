#!/usr/bin/env bash
# Auto-commit hook: commits changes to knowledge/, skills/, settings.json, CLAUDE.md
# Triggered by PostToolUse on Write/Edit operations

set -euo pipefail

FILE="$CLAUDE_TOOL_FILE_PATH"
REPO="$HOME/.claude"

# Only track specific paths
case "$FILE" in
  */knowledge/* | */skills/* | */settings.json | */CLAUDE.md | */.gitignore)
    cd "$REPO"
    git add -- "$FILE" 2>/dev/null || true

    # Commit only if there are staged changes
    if ! git diff --cached --quiet 2>/dev/null; then
      REL="${FILE#$REPO/}"
      git commit -m "auto: update ${REL}" --no-verify --quiet 2>/dev/null || true
    fi
    ;;
esac
