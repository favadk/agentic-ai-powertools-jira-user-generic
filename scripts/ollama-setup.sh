#!/usr/bin/env bash
# Ollama local LLM setup helper — Linux/macOS equivalent of ollama-setup.ps1
#
# Usage:
#   ./scripts/ollama-setup.sh                        # verify + smoke test (default)
#   ./scripts/ollama-setup.sh --verify               # check API + model presence
#   ./scripts/ollama-setup.sh --pull                 # pull model if missing
#   ./scripts/ollama-setup.sh --smoke-test           # send test prompt
#   ./scripts/ollama-setup.sh --status               # list installed models
#   ./scripts/ollama-setup.sh --model mistral        # specify model (default: llama3.2)
#   ./scripts/ollama-setup.sh --url http://host:11434

set -euo pipefail

MODEL="llama3.2"
OLLAMA_URL="http://localhost:11434"
DO_VERIFY=0; DO_PULL=0; DO_SMOKE=0; DO_STATUS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)       MODEL="$2"; shift 2 ;;
    --url)         OLLAMA_URL="$2"; shift 2 ;;
    --verify)      DO_VERIFY=1; shift ;;
    --pull)        DO_PULL=1; shift ;;
    --smoke-test)  DO_SMOKE=1; shift ;;
    --status)      DO_STATUS=1; shift ;;
    *)             shift ;;
  esac
done

# Default: verify + smoke
if [[ $DO_VERIFY -eq 0 && $DO_PULL -eq 0 && $DO_SMOKE -eq 0 && $DO_STATUS -eq 0 ]]; then
  DO_VERIFY=1; DO_SMOKE=1
fi

ok()   { echo "  [OK]  $*"; }
warn() { echo "  [!!]  $*"; }
err()  { echo "  [ERR] $*" >&2; }

echo ""
echo "=== Ollama Local LLM Setup Helper (Linux/macOS) ==="
echo "    Model  : $MODEL"
echo "    API URL: $OLLAMA_URL"
echo ""

# ---- Pre-flight: detect existing install ----
if command -v ollama &>/dev/null; then
  ok "Ollama already installed: $(ollama --version 2>&1)"
else
  warn "Ollama not found in PATH."
  if [[ $DO_PULL -eq 1 || $DO_VERIFY -eq 1 ]]; then
    echo "    Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama installed."
  else
    err "Install Ollama first: curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
  fi
fi

# ---- STATUS ----
if [[ $DO_STATUS -eq 1 ]]; then
  echo "--- Installed Models ---"
  MODELS=$(curl -sf "$OLLAMA_URL/api/tags" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || true)
  if [[ -z "$MODELS" ]]; then
    warn "No models installed or Ollama not running. Pull one: ollama pull llama3.2"
  else
    while IFS= read -r m; do ok "$m"; done <<< "$MODELS"
  fi
fi

# ---- VERIFY ----
if [[ $DO_VERIFY -eq 1 ]]; then
  echo "--- Verify ---"
  # Check service
  if curl -sf "$OLLAMA_URL/api/tags" &>/dev/null; then
    ok "Ollama API reachable at $OLLAMA_URL"
  else
    warn "Ollama service not running — starting..."
    ollama serve &>/dev/null &
    sleep 4
    if curl -sf "$OLLAMA_URL/api/tags" &>/dev/null; then
      ok "Ollama service started."
    else
      err "Ollama API still not reachable. Check logs: journalctl -u ollama"
      exit 1
    fi
  fi
  # Check model
  if ollama list 2>/dev/null | grep -q "^${MODEL}"; then
    ok "Model '$MODEL' is installed."
  else
    warn "Model '$MODEL' not found."
    if [[ $DO_PULL -eq 1 ]]; then
      echo "    Pulling '$MODEL'..."
      ollama pull "$MODEL"
      ok "Model '$MODEL' pulled."
    else
      warn "Pull it with: ollama pull $MODEL"
    fi
  fi
fi

# ---- PULL ----
if [[ $DO_PULL -eq 1 && $DO_VERIFY -eq 0 ]]; then
  if ollama list 2>/dev/null | grep -q "^${MODEL}"; then
    ok "Model '$MODEL' already present — skipping pull."
  else
    echo "    Pulling '$MODEL'..."
    ollama pull "$MODEL"
    ok "Model '$MODEL' pulled."
  fi
fi

# ---- SMOKE TEST ----
if [[ $DO_SMOKE -eq 1 ]]; then
  echo "--- Smoke Test ---"
  PROMPT='Respond with exactly: OK'
  RESPONSE=$(curl -sf "$OLLAMA_URL/api/generate" \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"$PROMPT\",\"stream\":false}" \
    2>/dev/null | grep -o '"response":"[^"]*"' | cut -d'"' -f4 || true)
  if [[ -n "$RESPONSE" ]]; then
    ok "Model responded: $RESPONSE"
    ok "Smoke test PASSED."
  else
    err "No response from model '$MODEL'. Is it fully loaded?"
    exit 1
  fi
fi

echo ""
ok "All checks complete."
