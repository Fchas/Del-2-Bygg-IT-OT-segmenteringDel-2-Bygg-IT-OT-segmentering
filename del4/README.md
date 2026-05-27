# Lab 2 Del 4: Incident Response in OT

**Status:** ✅ COMPLETE
**Target:** ICS-CERT incident report and evidence collection (evidence collected)

## Purpose
Denna mapp innehåller Del 4-material för incidentrespons i OT.
Den faktiska Del 3-sandboxen körs i en extern katalog:

`~/ais-lab2-sandboxes/del3`

## Vad som ska göras
1. Starta den externa Del 3-sandboxen:
   - `cd ~/ais-lab2-sandboxes/del3`
   - `docker compose up -d --build`
2. Observa baselineförhållanden:
   - `docker logs -f lab3-hmi`
   - `fast.log` bör visa normalt eller begränsat trafikmönster
   - Spara helst en screenshot i `screenshots/`
3. Kör attack och triangulering enligt labbens instruktioner.
4. Samla in bevis med skriptet i denna mapp:
   - `SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3 ./collect-evidence.sh`
5. Uppdatera `incident-report.md` med faktiska tidsstämplar, attacker och containmentsåtgärder.

## Filinnehåll
- `collect-evidence.sh` — Automatiserat skript för att hämta artefakter från Del 3-sandboxen
- `incident-report.md` — ICS-CERT-rapport för incidenten
- `reflection.md` — Reflektion över OT-säkerhet och labbens lärdomar
- `evidence/README.md` — Guide till artefaktsinsamling

## Hur du samlar bevis / Var bevis finns
Evidensfilerna har redan samlats in och ligger i `del4/evidence/`.

Om du vill samla om eller reproducera insamlingen, kör följande i `del4`:

```bash
cd /workspaces/Del-2-Bygg-IT-OT-segmenteringDel-2-Bygg-IT-OT-segmentering/del4
SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3 ./collect-evidence.sh
```

Om OT-nätverksnamnet skiljer sig från standarden `del3_ot`, använd också:

```bash
SANDBOX_DIR=/home/codespace/ais-lab2-sandboxes/del3 OT_NETWORK=del3_ot ./collect-evidence.sh
```

## Förväntade artefakter
- `del4/evidence/fast.log`
- `del4/evidence/eve.json`
- `del4/evidence/timeline.txt`
- `del4/evidence/ot-network.json`
- `del4/evidence/compose-state.txt`
- `del4/evidence/jump-history.txt`
- `del4/evidence/jump-processes.txt`
- `del4/evidence/plc-state.txt`

## Viktigt att notera
- `jump-history.txt` eller `plc-state.txt` kan vara tomma om informationen inte är tillgänglig i sandlådan.
- Om `127.0.0.1:2222` är upptaget på hosten, använd en annan port i sandboxens `docker-compose.yml`, t.ex. `127.0.0.1:2223:22`.
- Rapporten i `incident-report.md` ska baseras på de faktiska artefakterna i `del4/evidence/`.

## Slutsats
Del 4 är slutförd: evidens finns i `del4/evidence/`, `incident-report.md` och `reflection.md` är uppdaterade.

**Status:** ✅ COMPLETE — evidens samlad och rapport uppdaterad.
