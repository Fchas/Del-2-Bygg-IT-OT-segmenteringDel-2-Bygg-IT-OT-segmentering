#!/usr/bin/env bash
set -euo pipefail

# Usage: SANDBOX_DIR=/path/to/sandbox ./collect-evidence.sh
# Defaults assume the course sandbox is at /home/codespace/ais-lab2-sandboxes/del3

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX_DIR="${SANDBOX_DIR:-/home/codespace/ais-lab2-sandboxes/del3}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$REPO_DIR/del4/evidence}"
SURICATA_DIR="${SURICATA_DIR:-$SANDBOX_DIR/suricata-logs}"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-$SANDBOX_DIR/docker-compose.yml}"
JUMP_CONTAINER="${JUMP_CONTAINER:-lab3-jump}"
PLC_STATE_CONTAINER="${PLC_STATE_CONTAINER:-lab3-hmi}"
OT_NETWORK="${OT_NETWORK:-del3_ot}"

mkdir -p "$EVIDENCE_DIR"

detect_ot_network() {
  docker network ls --format '{{.Name}}' | grep -E '(_|^)ot$' | head -n1 || true
}

echo "Collecting evidence into $EVIDENCE_DIR"

copy_log() {
  local src="$1"
  local dest="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
    echo "  copied: $(basename "$src")"
  else
    echo "  missing: $(basename "$src")"
  fi
}

copy_log "$SURICATA_DIR/fast.log" "$EVIDENCE_DIR/fast.log"
copy_log "$SURICATA_DIR/eve.json" "$EVIDENCE_DIR/eve.json"

if command -v docker >/dev/null 2>&1; then
  echo "Collecting Docker evidence..."
  if docker network inspect "$OT_NETWORK" >/dev/null 2>&1; then
    docker network inspect "$OT_NETWORK" > "$EVIDENCE_DIR/ot-network.json"
    echo "  collected ot-network.json"
  else
    echo "  warning: Docker network $OT_NETWORK not found, attempting auto-detect..."
    autodetected=$(detect_ot_network)
    if [[ -n "$autodetected" ]] && docker network inspect "$autodetected" >/dev/null 2>&1; then
      docker network inspect "$autodetected" > "$EVIDENCE_DIR/ot-network.json"
      echo "  collected ot-network.json via auto-detected network: $autodetected"
    else
      echo "  warning: could not auto-detect an OT Docker network"
    fi
  fi

  if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
    docker compose -f "$DOCKER_COMPOSE_FILE" ps > "$EVIDENCE_DIR/compose-state.txt"
    echo "  collected compose-state.txt"
    docker compose -f "$DOCKER_COMPOSE_FILE" config >> "$EVIDENCE_DIR/compose-state.txt" 2>/dev/null || true
  else
    echo "  warning: compose file $DOCKER_COMPOSE_FILE not found"
  fi

  if docker ps --format '{{.Names}}' | grep -q "^${JUMP_CONTAINER}$"; then
    docker exec "$JUMP_CONTAINER" sh -c 'cat /root/.ash_history 2>/dev/null || true' > "$EVIDENCE_DIR/jump-history.txt" || true
    docker exec "$JUMP_CONTAINER" ps auxf > "$EVIDENCE_DIR/jump-processes.txt" || true
    echo "  collected jump history/processes"
  else
    echo "  warning: jump container $JUMP_CONTAINER not running"
  fi

  if docker ps --format '{{.Names}}' | grep -q "^${PLC_STATE_CONTAINER}$"; then
    docker exec "$PLC_STATE_CONTAINER" python3 - <<'PY' > "$EVIDENCE_DIR/plc-state.txt" 2>/dev/null || true
from pymodbus.client import ModbusTcpClient
c = ModbusTcpClient('mock-plc', port=502)
if c.connect():
    hr = c.read_holding_registers(0, 4, slave=1)
    co = c.read_coils(0, 2, slave=1)
    print('holding_registers=' + str(hr.registers if hr else 'N/A'))
    print('coils=' + str(co.bits if co else 'N/A'))
    c.close()
else:
    print('failed to connect to PLC')
PY
    echo "  collected plc-state.txt"
  else
    echo "  warning: PLC state container $PLC_STATE_CONTAINER not running"
  fi
else
  echo "Warning: docker command not available, skipping Docker evidence collection"
fi

if [[ -f "$EVIDENCE_DIR/fast.log" ]]; then
  grep -E "Modbus|sid|Modbus TCP|session|FC6|FC16|FC5" "$EVIDENCE_DIR/fast.log" | head -50 > "$EVIDENCE_DIR/timeline.txt" || true
  echo "  collected timeline.txt"
elif [[ -f "$EVIDENCE_DIR/eve.json" ]]; then
  jq -r '.[] | [.timestamp, .event_type, .alert.signature] | @tsv' "$EVIDENCE_DIR/eve.json" | head -50 > "$EVIDENCE_DIR/timeline.txt" || true
  echo "  collected timeline.txt from eve.json"
else
  echo "  no fast.log or eve.json available to generate timeline"
fi

echo "Evidence collection complete. Review files in $EVIDENCE_DIR"
