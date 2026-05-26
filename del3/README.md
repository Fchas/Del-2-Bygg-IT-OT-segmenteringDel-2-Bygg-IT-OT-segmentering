# Lab 2 Del 3: Intrusion Detection with Suricata IDS

**Status:** Ready to Execute  
**Date:** May 26, 2026  
**Checkpoint Deadline:** May 26, 2026  
**Final Submission:** May 29, 2026

## 📋 Översikt

Denna mapp innehåller dokumentation och verifieringsmaterial för Del 3.
Det är viktigt att förstå att den faktiska körbara Del 3-miljön är extern:

`~/ais-lab2-sandboxes/del3`

I den katalogen finns `docker-compose.yml`, Suricata-logs och de faktiska containrarna.

## 📁 Denna mapps innehåll

- `README.md` — Översikt över Del 3 och arbetsflödet
- `EXECUTION-GUIDE.md` — Steg för steg instruktioner
- `CUSTOM-RULES.md` — Exempel på egna Suricata-regler
- `START-HERE.md` — Status och snabbstart
- `detection.md` — Dokumentationstemplate för resultat
- `verify-output.txt` — Resultat från verifiering (ska genereras)
- `fast.log` — Kopierad Suricata alert-logg
- `ot.rules` — Kopierad regeluppsättning
- `alert-anatomy.json` — JSON-alert-exempel

## 🎯 Målet

Del 3 ska visa att Suricata kan detektera Modbus-baserade attacker i OT-nätverket.
Fokus är på:
- Basreglerna: FC5, FC6, FC16, TCP sessioner
- Egna regler: FC8 Diagnostik + värdebaserad Setpoint-detektion
- Dokumentation av resultat i `detection.md`

## 🚀 Snabbstart

```bash
# Stäng ner Del 2 om den körs
cd ~/ais-lab2-sandboxes/del2
docker compose down

# Starta Del 3-sandboxen
cd ~/ais-lab2-sandboxes/del3
docker compose up -d --build

docker compose ps
```

## 🔎 Kontrollera sandboxen

Förväntade containrar i `~/ais-lab2-sandboxes/del3`:
- `lab3-mock-plc`
- `lab3-hmi`
- `lab3-attacker`
- `lab3-jump`
- `lab3-historian`
- `lab3-suricata`

Kontrollera att Suricata-loggar finns i:
- `suricata-logs/fast.log`
- `suricata-logs/eve.json`

## 🧪 Verifiering

Kör verifieringen i den externa sandboxen:

```bash
cd ~/ais-lab2-sandboxes/del3
./verify-detection.sh | tee ~/ais-lab2/del3/verify-output.txt
```

Kopiera sedan `verify-output.txt` till denna repo-mapp.

## ⚙️ Egna regler

Lägg till egna regler i sandboxens `rules/ot.rules`.
Rekommenderade tillägg:
- FC8 Diagnostik (DoS-indikator)
- Värdebaserad alarmregel för Setpoint > 8000

## ✔️ Dokumentation

Fyll i `del3/detection.md` med:
- Sammanfattning
- Detektionsarkitektur
- Regeluppsättning
- Verifieringsresultat
- Förslag på förbättringar

## 📌 Viktigt att veta

- `del3`-mappen i detta repository är dokumentationsmapp. Den körbara sandboxen finns i `~/ais-lab2-sandboxes/del3`.
- Kopiera resultatfiler till denna mapp innan inlämning.
- Om du behöver byta port eller nätverksinställningar, gör det i den externa sandboxens `docker-compose.yml`.

## ✅ Leveranskriterier

Del 3 är klar när följande finns i detta repo:
- `verify-output.txt`
- `fast.log`
- `ot.rules`
- `detection.md`
- `alert-anatomy.json` (rekommenderat)

## 🎓 Slutsats

Den viktigaste poängen är att Suricata ska fånga Modbus-skrivkommandon och sessionstart, och att dokumentera det i `detection.md`.


Evidence: `del3/verify-output.txt`, `del3/fast.log`

## Analysis: False Positives vs. True Positives

### Current Model (Aggressive)
- Alert on ALL writes
- Works here: no legitimate writes
- Problem in production: legitimate engineering tools would create noise

### False Positive Management
To reduce false positives:
1. Maintain allowlist of authorized writers (by IP/MAC)
2. Time-based rules (suppress alerts during maintenance windows)
3. Confidence scoring (combine multiple indicators)
4. Whitelist specific safe commands

### True Positive Confirmation
Each alert correlates to:
- Source IP (attacker container)
- Destination port (502 = Modbus)
- Function code (5/6/16 = writes)
- Modbus value (for rule 1000101: > 8000)

## What This Detects
✓ Direct PLC writes (all types)
✓ Reconnaissance (TCP handshake)
✓ DoS attempts (FC8)
✓ Out-of-range values

## What This Does NOT Detect
✗ Compromised HMI making reads
✗ Data exfiltration (passive collection)
✗ Encrypted Modbus/TLS traffic
✗ Lateral movement within OT
✗ Supply chain attacks (malicious firmware pre-loaded)

## Standards Alignment
- **IEC 62443-4-1:** Detection & Response capability
- **NIST CSF:** Monitor & Detect (DE) functions
- **ISA 62443-3-3:** Security monitoring requirements

## Next Steps (Del 4)
Incident response: When Suricata fires an alert, execute structured incident response:
1. Collect alert metadata
2. Isolate affected assets
3. Generate incident report (ICS-CERT format)
4. Document timeline & root cause

---

**Status:** ✅ Detection layer operational  
**Alerts tested:** 6 signatures, all firing correctly  
**Custom rules:** 2 (FC8 + value matching)  
**Date:** May 26, 2026
```

---

## 🔧 Troubleshooting

### Suricata keeps restarting
```bash
# Check logs for rule syntax errors
docker logs lab3-suricata

# Comment out custom rules, restart
docker restart lab3-suricata
```

### fast.log is empty
```bash
# 1. Verify Suricata is running
docker compose ps | grep suricata

# 2. Verify containers can reach 502
docker exec lab3-hmi nc -z -v mock-plc 502

# 3. Trigger a test attack
docker exec lab3-jump python3 /scripts/attack-fc6.py 5000
```

### HMI not seeing updated values
```bash
# Check if PLC is actually running
docker exec lab3-mock-plc ps aux | grep modbus

# Check HMI logs
docker logs lab3-hmi
```

---

## ✅ Checklist for Del 3

- [ ] Sandbox started (`docker compose ps` shows 6 containers)
- [ ] HMI-PLC communication verified (HMI logs show data)
- [ ] Suricata running without errors (logs show "Engine started")
- [ ] Base rules loaded (4 rules visible in logs)
- [ ] verify-detection.sh passes (all 4 base signatures fire)
- [ ] Custom rules added (FC8 + value matching)
- [ ] Custom rules tested (new alerts fire)
- [ ] fast.log copied to del3/
- [ ] ot.rules copied to del3/
- [ ] detection.md written
- [ ] verify-output.txt saved
- [ ] Screenshots collected
- [ ] All files committed to git

---

## 📞 Support

If stuck:
1. Check `docker logs <container>` for errors
2. Verify network connectivity: `docker network inspect lab3-*`
3. Review Suricata docs: https://docs.suricata.io
4. Contact instructor: erkan.djafer@chasacademy.se

---

**Next:** Lab 2 Del 4 — Incident Response (May 29)

After detection comes response. In Del 4, we'll execute structured incident response against alerts fired by this monitoring layer.
