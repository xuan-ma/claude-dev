#!/usr/bin/env bash
# WeChat Connect — Wait for user reply by msg_id
#
# Polls ~/.claude/wechat-connect/run/replies.jsonl for a matching msg_id.
# Returns reply content on match, exits 1 on timeout.
#
# Usage:
#   wait-reply.sh --msg-id wc-1234567890-12345 --timeout 300
#
# Exit codes: 0=reply received (prints content), 1=timeout, 2=usage error

set -euo pipefail

MSG_ID=""
TIMEOUT=300
POLL_INTERVAL=5
REPLIES_FILE="$HOME/.claude/wechat-connect/run/replies.jsonl"

# ── Parse args ────────────────────────────────

while [ $# -gt 0 ]; do
  case "$1" in
    --msg-id)  MSG_ID="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [ -z "$MSG_ID" ]; then
  echo "[wait-reply.sh] ERROR: --msg-id is required" >&2
  exit 2
fi

# ── Poll loop ─────────────────────────────────

elapsed=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
  if [ -f "$REPLIES_FILE" ]; then
    REPLY=$(grep "\"msg_id\":\"$MSG_ID\"" "$REPLIES_FILE" 2>/dev/null | tail -1 || true)
    if [ -n "$REPLY" ]; then
      # Extract content field
      if command -v python3 >/dev/null 2>&1; then
        CONTENT=$(echo "$REPLY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))" 2>/dev/null)
      elif command -v python >/dev/null 2>&1; then
        CONTENT=$(echo "$REPLY" | python -c "import json,sys; print(json.load(sys.stdin).get('content',''))" 2>/dev/null)
      else
        CONTENT=$(echo "$REPLY" | grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/')
      fi
      echo "${CONTENT:-$REPLY}"
      exit 0
    fi
  fi
  sleep "$POLL_INTERVAL"
  elapsed=$((elapsed + POLL_INTERVAL))
done

echo "[wait-reply.sh] Timeout: no reply for msg_id=$MSG_ID after ${TIMEOUT}s" >&2
exit 1
