#!/usr/bin/env bash
# WeChat Connect — Send message via WeCom (企业微信) API
#
# Reads credentials from ~/.claude/wechat-connect/config.json
# Caches access_token in /tmp/wecom-token-cache.json
# Sends text/markdown message to specified user via WeCom API
#
# Usage:
#   send.sh --message "确认执行 X?" --to-user "ZhangSan"
#   send.sh --message "任务完成" --type markdown --to-user "ZhangSan"
#
# Exit codes: 0=success (prints msg_id), 1=config error, 2=API error, 3=timeout

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$HOME/.claude/wechat-connect/config.json"
TOKEN_CACHE="/tmp/wecom-token-cache.json"
PENDING_FILE="$HOME/.claude/wechat-connect/run/pending_msgs.jsonl"
RUN_DIR="$HOME/.claude/wechat-connect/run"

# ── Parse args ────────────────────────────────

MESSAGE=""
TO_USER=""
MSG_TYPE="text"

while [ $# -gt 0 ]; do
  case "$1" in
    --message) MESSAGE="$2"; shift 2 ;;
    --to-user) TO_USER="$2"; shift 2 ;;
    --type)    MSG_TYPE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [ -z "$MESSAGE" ]; then
  echo "[send.sh] ERROR: --message is required" >&2
  exit 1
fi

# ── Read config ───────────────────────────────

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[send.sh] ERROR: config not found at $CONFIG_FILE" >&2
  echo "[send.sh] Copy config.example.json to $CONFIG_FILE and fill in credentials" >&2
  exit 1
fi

_cfg_val() {
  # Extract a string value from config.json for a given top-level key.
  # Uses python -c (always available on the systems that run this skill)
  # but falls back to grep+sed for minimal environments.
  local key="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; print(json.load(open('$CONFIG_FILE')).get('$key',''))" 2>/dev/null
  elif command -v python >/dev/null 2>&1; then
    python -c "import json,sys; print(json.load(open('$CONFIG_FILE')).get('$key',''))" 2>/dev/null
  else
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CONFIG_FILE" 2>/dev/null \
      | head -1 | sed 's/.*: *"\(.*\)"/\1/'
  fi
}

CORPID="$(_cfg_val corpid)"
AGENTID="$(_cfg_val agentid)"
SECRET="$(_cfg_val secret)"

if [ -z "$TO_USER" ]; then
  TO_USER="$(_cfg_val default_user)"
fi

if [ -z "$CORPID" ] || [ -z "$SECRET" ] || [ "$CORPID" = "" ] || [ "$SECRET" = "" ]; then
  echo "[send.sh] ERROR: corpid or secret missing in $CONFIG_FILE" >&2
  exit 1
fi

if [ -z "$TO_USER" ]; then
  echo "[send.sh] ERROR: no --to-user and no default_user in config" >&2
  exit 1
fi

# ── Get access_token (with cache) ─────────────

_get_token() {
  local now token cached_at expires_in age

  # Return cached token if still valid (with 60s safety margin)
  if [ -f "$TOKEN_CACHE" ]; then
    if command -v python3 >/dev/null 2>&1; then
      read -r token cached_at expires_in < <(python3 -c "
import json,sys,time
d=json.load(open('$TOKEN_CACHE'))
print(d.get('token',''), d.get('cached_at',0), d.get('expires_in',7200))
" 2>/dev/null)
      now=$(python3 -c "import time; print(int(time.time()))" 2>/dev/null || date +%s)
      age=$((now - cached_at))
      if [ "$age" -lt "$((expires_in - 60))" ] && [ -n "$token" ]; then
        echo "$token"
        return 0
      fi
    fi
  fi

  # Fetch new token
  local resp
  resp=$(curl -sS --connect-timeout 10 --max-time 10 \
    "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${CORPID}&corpsecret=${SECRET}" 2>&1) || {
    echo "[send.sh] ERROR: gettoken request timed out" >&2
    exit 3
  }

  token=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null) || {
    # Python parse failed — check curl-level error
    if echo "$resp" | grep -qE 'Could not resolve|Connection refused|timed out'; then
      echo "[send.sh] ERROR: gettoken network error" >&2
      exit 3
    fi
  }

  if [ -z "$token" ]; then
    local errcode errmsg
    errcode=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('errcode','?'))" 2>/dev/null || echo "?")
    errmsg=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('errmsg','?'))" 2>/dev/null || echo "?")
    echo "[send.sh] ERROR: gettoken failed — errcode=$errcode errmsg=$errmsg" >&2
    exit 2
  fi

  # Cache it
  mkdir -p "$(dirname "$TOKEN_CACHE")"
  expires_in=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expires_in',7200))" 2>/dev/null || echo 7200)
  now=$(python3 -c "import time; print(int(time.time()))" 2>/dev/null || date +%s)
  echo "{\"token\":\"$token\",\"cached_at\":$now,\"expires_in\":$expires_in}" > "$TOKEN_CACHE"

  echo "$token"
}

ACCESS_TOKEN=$(_get_token)

# ── Generate msg_id ──────────────────────────

MSG_ID="wc-$(date +%s)-$RANDOM"

# ── Send message ──────────────────────────────

case "$MSG_TYPE" in
  text)
    CONTENT_JSON=$(python3 -c "import json; print(json.dumps({'content':'$MESSAGE'}))" 2>/dev/null)
    ;;
  markdown)
    CONTENT_JSON=$(python3 -c "import json; print(json.dumps({'content':'$MESSAGE'}))" 2>/dev/null)
    MSG_TYPE="markdown"
    ;;
  *)
    echo "[send.sh] ERROR: unsupported message type '$MSG_TYPE'" >&2
    exit 1
    ;;
esac

BODY=$(cat <<PAYLOAD
{
  "touser": "${TO_USER}",
  "msgtype": "${MSG_TYPE}",
  "agentid": ${AGENTID},
  "${MSG_TYPE}": ${CONTENT_JSON}
}
PAYLOAD
)

RESP=$(curl -sS --connect-timeout 10 --max-time 10 \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=${ACCESS_TOKEN}" 2>&1) || {
  echo "[send.sh] ERROR: message send timed out" >&2
  exit 3
}

ERRCODE=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('errcode',-1))" 2>/dev/null || echo -1)
ERRMSG=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('errmsg','unknown'))" 2>/dev/null || echo "unknown")

if [ "$ERRCODE" != "0" ]; then
  echo "[send.sh] ERROR: API returned errcode=$ERRCODE errmsg=$ERRMSG" >&2
  exit 2
fi

# ── Record pending message ───────────────────

mkdir -p "$RUN_DIR"
echo "{\"msg_id\":\"$MSG_ID\",\"to_user\":\"$TO_USER\",\"message\":\"$MESSAGE\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$PENDING_FILE"

echo "$MSG_ID"
