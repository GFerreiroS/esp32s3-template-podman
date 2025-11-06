#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_DIR="$WORKDIR/.vscode"
ENV_FILE="$VSCODE_DIR/env.json"
CCPP_FILE="$VSCODE_DIR/c_cpp_properties.json"

mkdir -p "$VSCODE_DIR"
mkdir -p "$HOME/.espressif"

usage() {
  echo "Usage: $0 [-d|--device] [PORT] [-m|--menu] [-l|--location PATH]"
  echo
  echo "  -d, --device PORT     Set serial device (e.g. /dev/ttyACM0)"
  echo "  -m, --menu            Launch menuconfig"
  echo "  -l, --location PATH   Mirror IDF headers for IntelliSense to PATH"
  echo
  echo "If no flags are provided, interactive setup runs."
  exit 0
}

PORT=""
MENUCONFIRM="n"
HEADER_PATH=""
INTELCONFIRM="n"

# --- Parse flags -----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      PORT="${2:-}"
      shift 2
      ;;
    -m|--menu)
      MENUCONFIRM="y"
      shift
      ;;
    -l|--location)
      HEADER_PATH="${2:-}"
      INTELCONFIRM="y"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1"; usage ;;
  esac
done

# --- Interactive if nothing specified --------------------------------------
if [[ -z "$PORT" && "$MENUCONFIRM" == "n" && "$INTELCONFIRM" == "n" ]]; then
  echo "=== ESP32-S3 Project Setup ==="
  echo
  PORT_CANDIDATE=$(ls -1 /dev/serial/by-id/* 2>/dev/null | head -n1 || true)
  if [ -z "$PORT_CANDIDATE" ]; then
    PORT_CANDIDATE=$(ls -1 /dev/ttyACM* /dev/ttyUSB* 2>/dev/null | head -n1 || true)
  fi
  read -rp "Enter serial port [${PORT_CANDIDATE:-/dev/ttyACM0}]: " PORT
  PORT=${PORT:-${PORT_CANDIDATE:-/dev/ttyACM0}}

  read -rp "Launch menuconfig now? [y/N]: " MENUCONFIRM
  MENUCONFIRM=${MENUCONFIRM:-n}

  read -rp "Set up IntelliSense (mirror IDF headers)? [Y/n]: " INTELCONFIRM
  INTELCONFIRM=${INTELCONFIRM:-y}

  if [[ "$INTELCONFIRM" =~ ^[Yy]$ ]]; then
    read -rp "Path to mirror ESP-IDF headers [~/.idf-sysroot/idf]: " HEADER_PATH
    HEADER_PATH=${HEADER_PATH:-"$HOME/.idf-sysroot/idf"}
  fi
fi

# --- Device setup ----------------------------------------------------------
if [[ -n "$PORT" ]]; then
  if [ ! -e "$PORT" ]; then
    echo "Error: $PORT not found."
    exit 1
  fi
  echo "[*] Using serial port: $PORT"
fi

# --- IntelliSense setup ----------------------------------------------------
if [[ "$INTELCONFIRM" =~ ^[Yy]$ && -n "$HEADER_PATH" ]]; then
  mkdir -p "$(dirname "$HEADER_PATH")"
  echo "[*] Syncing ESP-IDF headers to $HEADER_PATH ..."
  podman run --rm -it -v "$(dirname "$HEADER_PATH")":/host-idf:z espressif/idf:latest \
    bash -lc "rm -rf /host-idf/idf && cp -a /opt/esp/idf /host-idf/"
  echo "[*] Header mirror complete."

  if [[ -f "$CCPP_FILE" ]]; then
    echo "[*] Updating include path in c_cpp_properties.json"
    TMPFILE=$(mktemp)
    jq --arg path "$HEADER_PATH" \
      '.configurations[0].includePath |= map(if test("idf/components") then ($path + "/components/**") else . end)' \
      "$CCPP_FILE" > "$TMPFILE" && mv "$TMPFILE" "$CCPP_FILE"
  fi
fi

# --- Save environment ------------------------------------------------------
cat > "$ENV_FILE" <<EOF
{
  "serialPort": "$PORT",
  "idfHeaderPath": "$HEADER_PATH"
}
EOF
echo "[*] Saved configuration to $ENV_FILE"

# --- SDKCONFIG INIT --------------------------------------------------------
echo "[*] Generating sdkconfig..."
podman run --rm -it -v "$WORKDIR":/work:z -v "$HOME/.espressif":/root/.espressif:z \
  -w /work espressif/idf:latest bash -lc "idf.py set-target esp32s3"

# --- Menuconfig ------------------------------------------------------------
if [[ "$MENUCONFIRM" =~ ^[Yy]$ ]]; then
  echo "[*] Launching menuconfig..."
  podman run --rm -it -e TERM=xterm-256color -v "$WORKDIR":/work:z -v "$HOME/.espressif":/root/.espressif:z \
    -w /work espressif/idf:latest bash -lc "idf.py -B build menuconfig"
fi

echo
echo "Setup complete."
echo "Serial port: $PORT"
if [[ "$INTELCONFIRM" =~ ^[Yy]$ ]]; then
  echo "IntelliSense headers: $HEADER_PATH"
fi
echo
