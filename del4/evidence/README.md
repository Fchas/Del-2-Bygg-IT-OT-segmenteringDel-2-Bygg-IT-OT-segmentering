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
2. Copy Suricata logs:
   ```bash
   cp ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log "$EVIDENCE/"
   cp ~/ais-lab2-sandboxes/del3/suricata-logs/eve.json "$EVIDENCE/"
   ```
3. Save network and service state:
   ```bash
   docker network inspect lab2-del3-sandbox_ot > "$EVIDENCE/ot-network.json"
   docker compose -f ~/ais-lab2-sandboxes/del3/docker-compose.yml ps > "$EVIDENCE/compose-state.txt"
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
   grep -E "OT-|Modbus" ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log | head -50 > "$EVIDENCE/timeline.txt"
   ```

## Notes
- If the incident has not yet been executed, this guide prepares the evidence workflow.
- After completion, copy the generated files into this repository under `del4/evidence/`.
