---
name: wechat-connect
description: Use when Claude needs user confirmation for high-risk operations but the user may be away from keyboard — sends confirmation requests via WeCom (企业微信) and waits for replies. Triggers autonomously on destructive operations, long-task completion, ambiguous decisions, or high-risk commands. Do NOT trigger for routine read/search/status operations.
---

# WeChat Connect

Bidirectional communication bridge between Claude and user via WeCom (企业微信).
Claude sends confirmation requests to the user's phone and waits for replies,
enabling decision-making when the user is away from the computer.

## Goal

Let Claude reach the user through WeChat when:
- An irreversible action needs confirmation (delete, force push, etc.)
- A long-running task completes and the user should know
- An ambiguous situation requires human judgment
- A high-risk command is about to be executed

## Decision Tree

```
Is the operation...
  ├─ Destructive? (rm -rf, force push, drop table, overwrite remote) → TRIGGER
  ├─ High-risk? (production deploy, config change, permission modification) → TRIGGER
  ├─ Long task completed? (>5 min, user likely walked away) → TRIGGER
  ├─ Ambiguous? (multiple valid interpretations, needs human choice) → TRIGGER
  ├─ Routine? (read, search, git status, edit local files, run tests) → SKIP
  └─ User actively interacting? (responded <2 min ago) → SKIP
```

**Pre-flight check:** Before triggering, verify the daemon is running:
```bash
test -f ~/.claude/wechat-connect/run/server.pid && kill -0 $(cat ~/.claude/wechat-connect/run/server.pid) 2>/dev/null || echo "DAEMON_DOWN"
```
If DAEMON_DOWN: proceed without WeChat confirmation (warn user inline), do NOT block.

## Workflow

```
1. SEND     → send.sh --message "确认执行 X?" --to-user <default_user>
            → returns msg_id (or exit 1 on failure)
2. ANNOUNCE → "已通过企业微信请求确认，等待回复中... (msg: <id>)"
3. WAIT     → wait-reply.sh --msg-id <id> --timeout 300
            → returns reply content (or exit 1 on timeout)
4a. CONFIRMED → "收到微信回复: <reply>，继续执行。"
4b. TIMEOUT   → "微信确认超时(5min)，采用安全策略：跳过此操作。"
4c. SEND_FAIL → "企业微信发送失败，继续执行并在终端内请求确认。"
```

## Stage-Specific Behaviors

### Stage 1 — SEND
- Call `~/.claude/skills/wechat-connect/scripts/send.sh --message "..." --to-user <user>`
- If exit code ≠ 0: fallback to terminal confirmation, do NOT block
- On success: capture `msg_id` from stdout

### Stage 2 — WAIT
- Call `~/.claude/skills/wechat-connect/scripts/wait-reply.sh --msg-id <id> --timeout 300`
- Do NOT busy-wait or block the session excessively
- While waiting, Claude may continue with non-risky side work

### Stage 3 — HANDLE RESPONSE
- **User replied "确认/yes/ok/同意/Y"** → proceed with the operation
- **User replied "取消/no/拒绝/N"** → abort the operation
- **User replied with other content** → treat as feedback, ask clarifying follow-up
- **Timeout** → safe default: abort / skip the operation

## Constraints

Claude MUST pause and confirm via WeChat before:
- `git push --force` or any force push
- `rm -rf` on non-temp directories
- Database schema changes (migrations ok, DROP TABLE not)
- Production environment changes
- Permission / ownership modifications
- Any command with `sudo` or admin privileges
- Commands that would overwrite or delete tracked git files

Claude MAY confirm via WeChat for:
- Decisions with multiple valid approaches
- Tasks that complete after >5 minutes
- Questions that would benefit from user input before proceeding

Claude MUST NOT confirm via WeChat for:
- Any operation that takes <10 seconds
- Reading, searching, listing files
- Standard git workflow (commit, push without force, branch, merge)
- Editing files, writing code
- Running tests
- Any action the user explicitly instructed without "ask me first"

## Validation

1. **Never block on WeChat.** If send fails or daemon is down, fall through to inline terminal confirmation.
2. **Timeout = safe default.** 5-minute timeout means abort/skip, never auto-proceed.
3. **No information leak.** Never send code snippets, file contents, or sensitive data via WeChat messages — only send action descriptions.
4. **Anti-spam.** Don't send more than 3 WeChat messages in 10 minutes. Batch notifications when possible.
5. **Respect silence.** If user hasn't replied to 2+ consecutive WeChat messages, stop sending and fall back to terminal.

## Resources

| File | Purpose |
|------|---------|
| `scripts/send.sh` | Send message via WeCom API |
| `scripts/wait-reply.sh` | Poll for user reply by msg_id |
| `scripts/wecom-server.py` | HTTP callback receiver (Python stdlib only) |
| `scripts/wecom-daemon.sh` | Start/stop/status of server + cloudflared tunnel |
| `config.example.json` | Configuration template |
| `references/wecom-api.md` | WeCom API reference |

## Setup (one-time)

1. Copy `config.example.json` to `~/.claude/wechat-connect/config.json` and fill in WeCom credentials
2. Run `scripts/wecom-daemon.sh start` to start the callback server and tunnel
3. Configure the displayed tunnel URL as the callback URL in WeCom admin panel
4. Run `scripts/wecom-daemon.sh status` to verify everything is working
