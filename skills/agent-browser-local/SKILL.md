---
name: agent-browser-local
description: Browser automation using your local Comet browser profile (cookies, auth, extensions). Use when the user wants to browse with their real browser session instead of an isolated headless browser. Reuses the user's existing cookies, login sessions, and extensions.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(osascript:*), Bash(/Applications/Comet.app/*), Bash(pkill:*), Bash(curl:*), Bash(pgrep:*), Bash(kill:*), Bash(sleep:*)
---

# Local Browser Automation with agent-browser + Comet CDP

This skill connects agent-browser to the user's real local Comet browser via Chrome DevTools Protocol (CDP). This gives you access to the user's actual browser profile — cookies, login sessions, extensions, and all.

## Setup: Launch Browser with CDP

**Before any browser commands**, you must ensure Comet is running with CDP enabled. Do this ONCE per session, then reuse for all subsequent commands.

### Headed Mode (default — visible browser window)

```bash
# Kill any existing Comet to avoid "Opening in existing session" conflicts
pkill -9 -f Comet 2>/dev/null; sleep 2

# Launch with CDP
/Applications/Comet.app/Contents/MacOS/Comet --remote-debugging-port=${COMET_CDP_PORT:-9222} &disown 2>/dev/null
sleep 3

# Verify CDP is ready
curl -s http://localhost:${COMET_CDP_PORT:-9222}/json/version >/dev/null && echo "CDP ready"

# Bring window to foreground
osascript -e 'tell application "Comet" to activate'
```

### Headless Mode (no visible window, still uses real profile)

```bash
pkill -9 -f Comet 2>/dev/null; sleep 2

/Applications/Comet.app/Contents/MacOS/Comet --headless=new --remote-debugging-port=${COMET_CDP_PORT:-9222} &disown 2>/dev/null
sleep 3

curl -s http://localhost:${COMET_CDP_PORT:-9222}/json/version >/dev/null && echo "CDP ready"
```

### Check if Already Running

Before launching, check if Comet CDP is already available from a previous command in this session:

```bash
curl -s http://localhost:${COMET_CDP_PORT:-9222}/json/version >/dev/null 2>&1 && echo "ALREADY RUNNING" || echo "NEED TO LAUNCH"
```

**If already running, skip the launch step entirely.** This is critical for session reuse.

## Core Rule: Always Pass `--cdp`

Every `agent-browser` command MUST include `--cdp ${COMET_CDP_PORT:-9222}`. This connects to the local Comet instance instead of launching a new browser.

```bash
# CORRECT — uses local Comet
agent-browser --cdp ${COMET_CDP_PORT:-9222} open https://example.com
agent-browser --cdp ${COMET_CDP_PORT:-9222} snapshot -i
agent-browser --cdp ${COMET_CDP_PORT:-9222} click @e1

# WRONG — would launch isolated headless browser, losing auth
agent-browser open https://example.com
```

## Workflow

Every interaction follows this pattern:

1. **Ensure CDP is running** (check first, launch only if needed)
2. **Navigate**: `agent-browser --cdp 9222 open <url>`
3. **Snapshot**: `agent-browser --cdp 9222 snapshot -i` (get element refs like `@e1`, `@e2`)
4. **Interact**: Use refs to click, fill, select — always with `--cdp 9222`
5. **Re-snapshot**: After navigation or DOM changes, get fresh refs

```bash
# Check CDP
curl -s http://localhost:9222/json/version >/dev/null 2>&1 || { echo "Launch Comet first"; exit 1; }

# Navigate and interact
agent-browser --cdp 9222 open https://example.com/dashboard
agent-browser --cdp 9222 snapshot -i
# Output: @e1 [button] "Settings", @e2 [link] "Profile", ...
agent-browser --cdp 9222 click @e2
agent-browser --cdp 9222 snapshot -i  # Fresh refs after navigation
```

## Command Chaining

Commands can be chained with `&&`. Always include `--cdp` on each:

```bash
agent-browser --cdp 9222 open https://example.com && agent-browser --cdp 9222 wait --load networkidle && agent-browser --cdp 9222 snapshot -i
```

## Essential Commands

All standard agent-browser commands work — just prepend `--cdp 9222`:

```bash
# Navigation
agent-browser --cdp 9222 open <url>
agent-browser --cdp 9222 close              # Disconnects agent-browser (does NOT close Comet)

# Snapshot & Interaction
agent-browser --cdp 9222 snapshot -i
agent-browser --cdp 9222 click @e1
agent-browser --cdp 9222 fill @e2 "text"
agent-browser --cdp 9222 select @e3 "option"
agent-browser --cdp 9222 press Enter
agent-browser --cdp 9222 scroll down 500

# Information
agent-browser --cdp 9222 get text @e1
agent-browser --cdp 9222 get url
agent-browser --cdp 9222 get title

# Wait
agent-browser --cdp 9222 wait @e1
agent-browser --cdp 9222 wait --load networkidle

# Capture
agent-browser --cdp 9222 screenshot
agent-browser --cdp 9222 screenshot --full
agent-browser --cdp 9222 screenshot --annotate
```

## User Preferences

Ask the user on first invocation:
- **Headed or headless?** Default to headed so the user can see what's happening.
- If the user says "headed", bring Comet to the foreground with `osascript -e 'tell application "Comet" to activate'` after launch.

## Session Lifecycle

- **Launch once**: The browser persists for the entire Claude Code session
- **Reuse always**: Check CDP before every interaction, never re-launch if already running
- **Don't kill on "close"**: `agent-browser --cdp 9222 close` only disconnects agent-browser's Playwright session from the CDP endpoint. It does NOT close or kill Comet. The user's browser stays open.
- **No cleanup needed**: When the Claude Code session ends, Comet keeps running as the user's normal browser

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `COMET_CDP_PORT` | `9222` | CDP port for remote debugging |

## Troubleshooting

### "Opening in existing browser session"
Comet was already running without CDP. Kill it first, then relaunch with `--remote-debugging-port`:
```bash
pkill -9 -f Comet 2>/dev/null; sleep 2
/Applications/Comet.app/Contents/MacOS/Comet --remote-debugging-port=9222 &disown
```

### CDP not responding
Wait longer — some systems need 3-5 seconds for Comet to start:
```bash
for i in {1..10}; do curl -s http://localhost:9222/json/version >/dev/null 2>&1 && break; sleep 1; done
```

### Port already in use
Another process is using port 9222. Either kill it or use a different port:
```bash
COMET_CDP_PORT=9333 agent-browser --cdp 9333 open https://example.com
```
