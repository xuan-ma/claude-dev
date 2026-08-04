#!/usr/bin/env bash
# Auto-stage hook: stages changes to knowledge/, skills/, settings.json, CLAUDE.md
# Does NOT commit — commit is manual, confirmed with user first.
# Triggered by PostToolUse on Write/Edit operations

set -euo pipefail

FILE="$CLAUDE_TOOL_FILE_PATH"
REPO="$HOME/.claude"

case "$FILE" in
  */knowledge/* | */skills/* | */settings.json | */CLAUDE.md | */.gitignore)
    cd "$REPO"
    git add -- "$FILE" 2>/dev/null || true
    ;;
esac
