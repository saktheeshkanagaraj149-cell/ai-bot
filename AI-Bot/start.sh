#!/usr/bin/env bash
#
# AI Bot — Offline Qwen Chatbot (Linux / macOS)
#
# Usage:  ./start.sh
#         AI_BOT_MODEL=1.5B ./start.sh   (override model choice)
#
# Double-click (where supported) or run from a terminal.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  AI Bot - Offline Qwen Chatbot"
echo "=========================================="

# ------------------------------------------------------------------
# User override: AI_BOT_MODEL=1.5B or 3B
# ------------------------------------------------------------------
MODEL_CHOICE="${AI_BOT_MODEL:-}"

# ------------------------------------------------------------------
# Detect total physical RAM (MB)
# ------------------------------------------------------------------
if [[ "$(uname)" == "Darwin" ]]; then
    TOTAL_RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    TOTAL_RAM_MB=$(( TOTAL_RAM_BYTES / 1024 / 1024 ))
else
    TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}')
fi
[[ -z "${TOTAL_RAM_MB:-}" || "$TOTAL_RAM_MB" -eq 0 ]] && TOTAL_RAM_MB=4096

# ------------------------------------------------------------------
# Auto-select model: 1.5B if RAM < 6 GB, else 3B
# ------------------------------------------------------------------
if [[ -z "$MODEL_CHOICE" ]]; then
    if [[ "$TOTAL_RAM_MB" -lt 6144 ]]; then
        MODEL_CHOICE="1.5B"
    else
        MODEL_CHOICE="3B"
    fi
fi

# ------------------------------------------------------------------
# Map model choice to filename + label
# ------------------------------------------------------------------
case "$MODEL_CHOICE" in
    1.5B)
        MODEL_FILE="qwen2.5-1.5b-instruct-q4_k_m.gguf"
        MODEL_LABEL="Qwen2.5-1.5B-Instruct (fast, low-RAM PCs)"
        ;;
    3B)
        MODEL_FILE="qwen2.5-3b-instruct-q4_k_m.gguf"
        MODEL_LABEL="Qwen2.5-3B-Instruct (better quality)"
        ;;
    *)
        echo "ERROR: Invalid AI_BOT_MODEL '$MODEL_CHOICE'. Use 1.5B or 3B."
        exit 1
        ;;
esac

BIN_DIR="$SCRIPT_DIR/bin"
MODEL_PATH="$SCRIPT_DIR/models/$MODEL_FILE"
UI_PATH="$SCRIPT_DIR/app/index.html"

# Prefer CPU build; fall back to Vulkan build if present
SERVER_EXE="$BIN_DIR/llama-server"
if [[ ! -x "$SERVER_EXE" ]]; then
    SERVER_EXE="$BIN_DIR/llama-server-vulkan"
fi
if [[ ! -x "$SERVER_EXE" ]]; then
    # macOS may ship binary named llama-server.macos or similar
    SERVER_EXE=$(ls "$BIN_DIR"/llama-server* 2>/dev/null | head -n1)
fi

# ------------------------------------------------------------------
# Validate llama-server + model
# ------------------------------------------------------------------
if [[ ! -x "$SERVER_EXE" ]]; then
    echo "ERROR: llama-server not found in $BIN_DIR"
    echo "       Place the CPU (or Vulkan) build of llama-server in the bin folder."
    echo "       See README.txt for download details."
    exit 1
fi

if [[ ! -f "$MODEL_PATH" ]]; then
    echo "ERROR: Model file not found: $MODEL_PATH"
    echo "       Download the GGUF file and place it in the models folder."
    echo "       See README.txt for exact filenames and download links."
    exit 1
fi

# ------------------------------------------------------------------
# Thread count: nproc, cap at 8, floor at 1
# ------------------------------------------------------------------
CPU_COUNT=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
THREADS=$CPU_COUNT
[[ "$THREADS" -gt 8 ]] && THREADS=8
[[ "$THREADS" -lt 1 ]] && THREADS=1

echo
echo "[AI Bot] Model      : $MODEL_LABEL"
echo "[AI Bot] Auto-pick  : based on ${TOTAL_RAM_MB} MB RAM"
echo "[AI Bot] Threads    : $THREADS"
echo "[AI Bot] Context    : 4096"
echo "[AI Bot] API        : http://127.0.0.1:8080"
echo

# ------------------------------------------------------------------
# Kill any stale llama-server so port 8080 is free
# ------------------------------------------------------------------
pkill -f llama-server >/dev/null 2>&1 || true
sleep 1

# ------------------------------------------------------------------
# Start llama-server in the background; capture PID
# ------------------------------------------------------------------
echo "[AI Bot] Starting llama-server..."
"$SERVER_EXE" -m "$MODEL_PATH" -c 4096 -t "$THREADS" --host 127.0.0.1 --port 8080 --cors > "$SCRIPT_DIR/ai-bot-server.log" 2>&1 &
SERVER_PID=$!

cleanup() {
    if [[ -n "${SERVER_PID:-}" ]]; then
        kill "$SERVER_PID" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------
# Wait for the server to be ready (up to 60 seconds)
# Try curl first, fall back to a bash /dev/tcp connect check
# ------------------------------------------------------------------
echo "[AI Bot] Waiting for server to be ready..."
READY=0
port_open() {
    (echo > /dev/tcp/127.0.0.1/8080) >/dev/null 2>&1
}
server_ok() {
    if command -v curl >/dev/null 2>&1; then
        curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1
    else
        port_open
    fi
}

for i in $(seq 1 60); do
    if server_ok; then
        READY=1
        break
    fi
    sleep 1
done

if [[ "$READY" -eq 1 ]]; then
    echo "[AI Bot] Server is ready."
    echo "[AI Bot] Opening $UI_PATH in your default browser..."
    if [[ "$(uname)" == "Darwin" ]]; then
        open "$UI_PATH"
    else
        xdg-open "$UI_PATH" >/dev/null 2>&1 || gnome-open "$UI_PATH" >/dev/null 2>&1 || \
            echo "       Please open this file in your browser: $UI_PATH"
    fi

    echo
    echo "=========================================="
    echo "  The bot is running in your browser."
    echo "  Press Ctrl+C to stop the server."
    echo "  Logs: $SCRIPT_DIR/ai-bot-server.log"
    echo "=========================================="
    echo

    # Block until the user presses Ctrl+C (then trap kills the server)
    wait "$SERVER_PID" 2>/dev/null || true
else
    echo
    echo "[AI Bot] ERROR: Server did not become ready in time."
    echo "[AI Bot] Check the log: $SCRIPT_DIR/ai-bot-server.log"
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    exit 1
fi
