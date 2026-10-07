#!/usr/bin/env bash
# Starts the QA Framework Setup Wizard on Linux/macOS.
# Uses PowerShell Core (pwsh) if available for the API server; falls back to file:// mode.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIZARD="$SCRIPT_DIR/index.html"
PORT=7420

if [ ! -f "$WIZARD" ]; then
  echo "ERROR: Setup wizard not found at: $WIZARD" >&2; exit 1
fi

open_browser() {
  local url="$1"
  if command -v xdg-open &>/dev/null; then xdg-open "$url"
  elif command -v open &>/dev/null; then open "$url"
  elif command -v wslview &>/dev/null; then wslview "$url"
  else echo "Open manually: $url"; fi
}

# Preferred: use pwsh server (same as Windows)
if command -v pwsh &>/dev/null; then
  echo "=== Agentic AI QA Framework Setup Wizard ==="
  echo "  Server : http://localhost:$PORT"
  echo "  Press Ctrl+C to stop."
  open_browser "http://localhost:$PORT/"
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/Start-SetupWizard.ps1"
else
  # Fallback: serve static file via Python HTTP server + proxy API via shell
  echo "pwsh not found — opening in file:// mode (download scripts manually)."
  open_browser "file://$WIZARD"
fi

