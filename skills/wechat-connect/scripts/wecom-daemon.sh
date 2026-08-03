#!/usr/bin/env bash
# WeChat Connect — Daemon manager
#
# Starts the WeCom callback server + cloudflared tunnel in background.
# Provides: start, stop, status, restart
#
# Usage:
#   wecom-daemon.sh start     # Start server + tunnel
#   wecom-daemon.sh stop      # Stop everything
#   wecom-daemon.sh status    # Check if running
#   wecom-daemon.sh restart   # Restart

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_DIR="$HOME/.claude/wechat-connect/run"
PID_FILE="$RUN_DIR/server.pid"
TUNNEL_PID_FILE="$RUN_DIR/tunnel.pid"
TUNNEL_URL_FILE="$RUN_DIR/tunnel-url.txt"
LOG_FILE="$RUN_DIR/server.log"

mkdir -p "$RUN_DIR"

# ── Helpers ────────────────────────────────────

_is_running() {
  local pid_file="$1"
  if [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file" 2>/dev/null || true)
    case "$pid" in
      ''|*[!0-9]*|0|1) rm -f "$pid_file"; return 1 ;;
    esac
    kill -0 "$pid" 2>/dev/null && return 0
    rm -f "$pid_file"
  fi
  return 1
}

_find_python() {
  if command -v python3 >/dev/null 2>&1; then echo python3
  elif command -v python >/dev/null 2>&1; then echo python
  else
    echo "[wecom-daemon] ERROR: Python not found" >&2
    exit 1
  fi
}

# ── Start ──────────────────────────────────────

cmd_start() {
  if _is_running "$PID_FILE"; then
    echo "[wecom-daemon] Already running (PID $(cat "$PID_FILE"))"
    return 0
  fi

  PYTHON=$(_find_python)

  # Check config
  CONFIG="$HOME/.claude/wechat-connect/config.json"
  if [ ! -f "$CONFIG" ]; then
    echo "[wecom-daemon] ERROR: config not found at $CONFIG" >&2
    echo "[wecom-daemon] Copy $SKILL_DIR/config.example.json to $CONFIG and fill in credentials" >&2
    exit 1
  fi

  # Start callback server
  echo "[wecom-daemon] Starting callback server on localhost:19800..."
  nohup "$PYTHON" "$SCRIPT_DIR/wecom-server.py" --host 127.0.0.1 --port 19800 \
    >> "$LOG_FILE" 2>&1 &
  SERVER_PID=$!
  echo "$SERVER_PID" > "$PID_FILE"
  sleep 1

  if ! _is_running "$PID_FILE"; then
    echo "[wecom-daemon] ERROR: Server failed to start. Check $LOG_FILE" >&2
    exit 1
  fi
  echo "[wecom-daemon] Server started (PID $SERVER_PID)"

  # Start cloudflared tunnel
  if command -v cloudflared >/dev/null 2>&1; then
    echo "[wecom-daemon] Starting cloudflared tunnel..."
    nohup cloudflared tunnel --url http://localhost:19800 \
      >> "$RUN_DIR/tunnel.log" 2>&1 &
    TUNNEL_PID=$!
    echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"

    # Wait for tunnel URL
    for _ in $(seq 1 15); do
      if [ -f "$RUN_DIR/tunnel.log" ]; then
        URL=$(grep -o 'https://[a-z0-9.-]*\.trycloudflare\.com' "$RUN_DIR/tunnel.log" 2>/dev/null | head -1 || true)
        if [ -n "$URL" ]; then
          echo "$URL" > "$TUNNEL_URL_FILE"
          echo ""
          echo "  ╔══════════════════════════════════════════════════════╗"
          echo "  ║  企业微信回调 URL (WeCom Callback URL)               ║"
          echo "  ╠══════════════════════════════════════════════════════╣"
          echo "  ║  $URL/wecom/callback  ║"
          echo "  ╚══════════════════════════════════════════════════════╝"
          echo ""
          echo "  Copy this URL to WeCom admin panel → Application → Receive Messages → URL"
          break
        fi
      fi
      sleep 1
    done
  else
    echo ""
    echo "  ⚠  cloudflared not found. Install it for callback support:"
    echo "     https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
    echo ""
    echo "  Without cloudflared, you can ONLY send messages, NOT receive replies."
    echo "  For bidirectional communication, install cloudflared and restart:"
    echo "    wecom-daemon.sh restart"
    echo ""
  fi
}

# ── Stop ───────────────────────────────────────

cmd_stop() {
  for pid_file in "$PID_FILE" "$TUNNEL_PID_FILE"; do
    if [ -f "$pid_file" ]; then
      pid=$(cat "$pid_file" 2>/dev/null || true)
      if [ -n "$pid" ] && kill "$pid" 2>/dev/null; then
        echo "[wecom-daemon] Stopped PID $pid"
      fi
      rm -f "$pid_file"
    fi
  done
  echo "[wecom-daemon] Stopped"
}

# ── Status ─────────────────────────────────────

cmd_status() {
  if _is_running "$PID_FILE"; then
    echo "[wecom-daemon] Server: RUNNING (PID $(cat "$PID_FILE"))"
  else
    echo "[wecom-daemon] Server: STOPPED"
  fi

  if _is_running "$TUNNEL_PID_FILE"; then
    echo "[wecom-daemon] Tunnel: RUNNING (PID $(cat "$TUNNEL_PID_FILE"))"
    if [ -f "$TUNNEL_URL_FILE" ]; then
      echo "[wecom-daemon] URL:    $(cat "$TUNNEL_URL_FILE")/wecom/callback"
    fi
  else
    echo "[wecom-daemon] Tunnel: STOPPED"
  fi

  # Check config
  CONFIG="$HOME/.claude/wechat-connect/config.json"
  if [ -f "$CONFIG" ]; then
    echo "[wecom-daemon] Config: $CONFIG"
  else
    echo "[wecom-daemon] Config: MISSING — copy config.example.json to $CONFIG"
  fi
}

# ── Dispatch ──────────────────────────────────

case "${1:-status}" in
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  status)  cmd_status ;;
  restart) cmd_stop; sleep 1; cmd_start ;;
  *)
    echo "Usage: wecom-daemon.sh {start|stop|status|restart}"
    exit 1
    ;;
esac
