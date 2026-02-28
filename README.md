# agent-browser-local

A [Claude Code](https://claude.com/claude-code) skill that connects [agent-browser](https://github.com/nicepkg/agent-browser) to your **real local browser** via Chrome DevTools Protocol (CDP).

Instead of using an isolated headless Chromium, this skill launches your local Comet browser with CDP enabled — giving agent-browser full access to your existing cookies, login sessions, and extensions.

## Install

```bash
npx skills add nwparker/agent-browser-local -y
```

## Usage

In Claude Code, invoke the skill:

```
/agent-browser-local go to https://myapp.com/dashboard
```

The skill will:
1. Launch Comet with CDP on port 9222 (or check if already running)
2. Connect agent-browser to it via `--cdp 9222`
3. Navigate, snapshot, interact — with your real browser profile

## Headed vs Headless

By default, Comet launches **headed** (visible window). Tell the agent "use headless" if you don't need to see the browser.

- **Headed**: Comet window appears, brought to foreground. You can watch agent-browser drive it in real time.
- **Headless**: Comet runs in the background with `--headless=new`. Still uses your real profile, just no visible window.

## Standalone Script

You can also launch Comet with CDP manually:

```bash
./scripts/launch-comet-cdp.sh                # Headed, port 9222
./scripts/launch-comet-cdp.sh --headless     # Headless, port 9222
./scripts/launch-comet-cdp.sh --port 9333    # Custom port
```

Then use agent-browser directly:

```bash
agent-browser --cdp 9222 open https://example.com
agent-browser --cdp 9222 snapshot -i
```

## Requirements

- [Comet Browser](https://cometbrowser.com) installed at `/Applications/Comet.app`
- [agent-browser](https://github.com/nicepkg/agent-browser) CLI installed (`npm install -g agent-browser`)
- macOS (for `osascript` window management)

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `COMET_CDP_PORT` | `9222` | CDP remote debugging port |

## Future Plans

- Support for additional Chromium-based browsers (Brave, Arc, Chrome, Edge)
- Linux and Windows support
