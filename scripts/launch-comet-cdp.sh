#!/bin/bash
# Launch Comet browser with CDP (Chrome DevTools Protocol) enabled
#
# Usage:
#   ./launch-comet-cdp.sh                    # Headed on port 9222
#   ./launch-comet-cdp.sh --headless         # Headless on port 9222
#   ./launch-comet-cdp.sh --port 9333        # Headed on custom port
#   ./launch-comet-cdp.sh --headless --port 9333
#
# Then use with agent-browser:
#   agent-browser --cdp 9222 open "https://example.com"
#   agent-browser --cdp 9222 snapshot -i

PORT="${COMET_CDP_PORT:-9222}"
HEADLESS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --headless) HEADLESS=true; shift ;;
    --port) PORT="$2"; shift 2 ;;
    --port=*) PORT="${1#*=}"; shift ;;
    *) PORT="$1"; shift ;;
  esac
done

# Check if CDP is already running on this port
if curl -s "http://localhost:$PORT/json/version" >/dev/null 2>&1; then
  echo "Comet CDP already running on port $PORT"
  echo "  DevTools:  http://localhost:$PORT"
  echo "  Targets:   http://localhost:$PORT/json"
  exit 0
fi

# Kill existing Comet instances to avoid "Opening in existing session"
if pgrep -f "Comet" >/dev/null 2>&1; then
  echo "Killing existing Comet instances..."
  pkill -9 -f Comet 2>/dev/null
  sleep 2
fi

# Build launch args
ARGS=("--remote-debugging-port=$PORT")
if [ "$HEADLESS" = true ]; then
  ARGS+=("--headless=new")
fi

/Applications/Comet.app/Contents/MacOS/Comet "${ARGS[@]}" &disown 2>/dev/null

# Wait for CDP to be ready
for i in {1..10}; do
  if curl -s "http://localhost:$PORT/json/version" >/dev/null 2>&1; then
    MODE="headed"
    [ "$HEADLESS" = true ] && MODE="headless"
    echo "Comet CDP ready ($MODE) on port $PORT"
    echo "  DevTools:  http://localhost:$PORT"
    echo "  Targets:   http://localhost:$PORT/json"
    echo ""
    echo "Use with agent-browser:"
    echo "  agent-browser --cdp $PORT open \"https://example.com\""
    echo "  agent-browser --cdp $PORT snapshot -i"

    # Bring to foreground if headed
    if [ "$HEADLESS" = false ]; then
      osascript -e 'tell application "Comet" to activate' 2>/dev/null
    fi
    exit 0
  fi
  sleep 0.5
done

echo "ERROR: CDP did not start on port $PORT" >&2
exit 1
