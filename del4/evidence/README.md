# Evidence Collection Guide — Del 4

This folder is reserved for the incident evidence artifacts generated during Del 4.

## Intended files
- `fast.log` — Suricata alert log covering the incident
- `eve.json` — Suricata JSON alert/event log
- `jump-history.txt` — attacker commands from the jump server shell history
- `jump-processes.txt` — process list from the jump server at containment time
- `plc-state.txt` — PLC holding register and coil state during containment
- `timeline.txt` — extracted timeline of Suricata OT alerts
- `ot-network.json` — OT network inspection output
- `compose-state.txt` — Docker Compose service state snapshot

## How to collect
1. Create a timestamped evidence folder:
   ```bash
   EVIDENCE=~/ais-lab2/del4/evidence-$(date -u +%Y%m%dT%H%M%SZ)
   mkdir -p "$EVIDENCE"
   ```
2. Copy Suricata logs from the Del 3 sandbox:
   ```bash
   SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3
   cp "$SANDBOX_DIR/suricata-logs/fast.log" "$EVIDENCE/"
   cp "$SANDBOX_DIR/suricata-logs/eve.json" "$EVIDENCE/"
   ```
3. Save network and service state:
   ```bash
   SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3
   OT_NETWORK=del3_ot
   docker compose -f "$SANDBOX_DIR/docker-compose.yml" ps > "$EVIDENCE/compose-state.txt"
   docker network inspect "$OT_NETWORK" > "$EVIDENCE/ot-network.json"
   ```
4. Save jump-server memory and commands:
   ```bash
   docker exec lab3-jump cat /root/.ash_history > "$EVIDENCE/jump-history.txt" 2>/dev/null || true
   docker exec lab3-jump ps auxf > "$EVIDENCE/jump-processes.txt"
   ```
5. Record PLC state:
   ```bash
   docker exec lab3-hmi python3 -c "from pymodbus.client import ModbusTcpClient; c = ModbusTcpClient('mock-plc', port=502); c.connect(); hr = c.read_holding_registers(0,4,slave=1).registers; co = c.read_coils(0,2,slave=1).bits; print(f'HR: {hr}\nCO: {co}'); c.close()" > "$EVIDENCE/plc-state.txt"
   ```
6. Create a timeline extract:
   ```bash
   grep -E "OT-|Modbus" "$SANDBOX_DIR/suricata-logs/fast.log" | head -50 > "$EVIDENCE/timeline.txt"
   ```

## Automation script
You can automate evidence collection using `del4/collect-evidence.sh`.

```bash
cd /workspaces/Del-2-Bygg-IT-OT-segmenteringDel-2-Bygg-IT-OT-segmentering/del4
chmod +x collect-evidence.sh
./collect-evidence.sh
```

If your sandbox is not in the default location, set `SANDBOX_DIR` first:

```bash
SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3 ./collect-evidence.sh
```

If your Docker network name differs from the default `del3_ot`, set `OT_NETWORK` as well:

```bash
SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3 OT_NETWORK=del3_ot ./collect-evidence.sh
```

## Notes
- The Del 3 sandbox runtime is expected under `~/ais-lab2-sandboxes/del3`; the `del3/` folder in this repository contains lab documentation only.
- If the sandbox fails to start because host port `2222` is already in use by local SSH, update the sandbox compose file to use a different host port (for example `127.0.0.1:2223:22`) or remove the host port mapping if you only need `docker exec lab3-jump`.
- After completion, copy the generated files into this repository under `del4/evidence/`.
