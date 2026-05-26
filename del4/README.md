# Lab 2 Del 4: Incident Response in OT

**Status:** Draft ready
**Target:** ICS-CERT incident report and Del 4 evidence collection

## Purpose
This folder contains the Del 4 incident response artifacts and a guided workflow for executing the attack, triage, containment, evidence collection, recovery, and lessons steps.

## What to do next
1. Start the Del 3 sandbox:
   - `cd ~/ais-lab2-sandboxes/del3`
   - `docker compose up -d --build`
2. Capture baseline state before the attack:
   - HMI output from `docker logs -f lab3-hmi`
   - Suricata `fast.log` should be empty or contain only benign baseline traffic
   - Save a screenshot as `screenshots/baseline.png`
3. Run the attack from the jump server:
   - `docker exec lab3-jump nmap -p 502 --open 172.31.50.0/24`
   - `docker exec lab3-jump python3 /scripts/attack-fc16.py`
   - `docker exec lab3-jump python3 /scripts/attack-fc6.py 5500`
   - Record the UTC timestamp with `date -u '+%Y-%m-%dT%H:%M:%SZ'`
4. Switch to IR mode and perform triage, containment, evidence collection, recovery, and eradication as documented in `del4/incident-report.md`.

## Files in this folder
- `incident-report.md` — Draft ICS-CERT incident report
- `reflection.md` — OT security reflection (400–600 words)
- `evidence/README.md` — Evidence collection instructions and artifact guide

## Notes
- The report is prepared from the Del 4 workflow and should be updated with exact timestamps, signatures, and attacker IPs after the live execution.
- The evidence folder contains an artifact collection plan; populate it with the actual files once the incident is executed.
