#!/usr/bin/env bash
# Auto-stage hook: stages changes to knowledge/, skills/, settings.json, CLAUDE.md
# Does NOT commit — commit is manual, confirmed with user first.
# Triggered by PostToolUse on Write/Edit operations

set -euo pipefail

FILE="$CLAUDE_TOOL_FILE_PATH"
REPO="$HOME/.claude"

case "$FILE" in
  */knowledge/*)
    cd "$REPO"
    git add -- "$FILE" 2>/dev/null || true
    # Regenerate human-readable README when knowledge files change
    [ "$FILE" != "*/README.md" ] && bash "$REPO/scripts/generate-readme.sh" 2>/dev/null || true
    git add "$REPO/knowledge/README.md" 2>/dev/null || true
    ;;
  */skills/* | */settings.json | */CLAUDE.md | */.gitignore)
    cd "$REPO"
    git add -- "$FILE" 2>/dev/null || true
    ;;
esac
