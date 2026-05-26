# Lab 2 Del 3 — Quick Execution Guide

## Timeline: 30 min active + 30 min documentation

---

## 🚀 STEP 1: Prepare (2 min)

### 1.1 Stop Del 2 sandbox if running
```bash
cd ~/ais-lab2-sandboxes/del2
docker compose down
```

### 1.2 Navigate to Del 3
```bash
cd ~/ais-lab2-sandboxes/del3
mkdir -p suricata-logs
```

### 1.3 Verify files exist
```bash
ls -la
# Should show: docker-compose.yml, verify-detection.sh, rules/ot.rules
```

---

## 🐳 STEP 2: Start Sandbox (3 min)

### 2.1 Build and start (first time ~1-2 min for pip install)
```bash
docker compose up -d --build
# Watch for build progress...
```

### 2.2 Wait for all 6 containers to start
```bash
# Wait ~30 seconds for full startup
sleep 30

# Verify all running
docker compose ps

# Should show 6 containers: "Up" status
#  - lab3-mock-plc
#  - lab3-hmi
#  - lab3-attacker
#  - lab3-jump
#  - lab3-historian
#  - lab3-suricata
```

---

## ✅ STEP 3: Verify HMI-PLC Communication (2 min)

### 3.1 Watch HMI logs
```bash
docker logs -f lab3-hmi

# Expected output (repeating every second):
# [HMI] SP=5000 TL=3050 PS=80 CL=495
# [HMI] SP=5000 TL=3100 PS=80 CL=490
# [HMI] SP=5000 TL=3150 PS=80 CL=485

# Ctrl+C to stop watching
```

**What it means:**
- SP = Setpoint (holding register 0) = 5000
- TL = Tank Level (holding register 1) = increasing (3050→3100→3150)
- PS = Pump Speed (holding register 2) = 80
- CL = Coolant Level (holding register 3) = decreasing

✅ **Good sign:** Tank level is rising — PLC is responding to HMI reads

---

## 🔍 STEP 4: Verify Suricata Health (2 min)

### 4.1 Check Suricata startup logs
```bash
docker logs lab3-suricata 2>&1 | tail -30

# Look for these key lines:
# - "4 rules successfully loaded"
# - "App-Layer Protocol Detection" and "modbus"
# - "br-lab3-ot: creating 2 threads"
# - "Engine started"
```

**If you see errors:**
- Rule syntax error → check `rules/ot.rules`
- Port already in use → `docker compose down` and retry
- OOM → system low on RAM → close other apps

### 4.2 Quick health check
```bash
docker exec lab3-suricata suricata -T -c /etc/suricata/suricata.yaml 2>&1 | head -20
# Should show "All OK" without errors
```

✅ **Good sign:** No errors, rules loaded, engine running

---

## 🎯 STEP 5: Run Automated Detection (5 min)

### 5.1 Run verification script
```bash
cd ~/ais-lab2-sandboxes/del3
./verify-detection.sh

# Expected output:
# ════════════════════════════════════════════════════════════════════
#  Lab 2 Del 3 — Detection verifier
# ════════════════════════════════════════════════════════════════════
#
# Triggering attacks from jump-server...
#
#  Checking ./suricata-logs/fast.log for alerts...
#
#   ✓ FIRED  FC6  Write Single Register                   sid:2000006
#   ✓ FIRED  FC5  Force Single Coil                       sid:2000005
#   ✓ FIRED  FC16 Write Multiple Registers                sid:2000016
#   ✓ FIRED  New Modbus TCP session                       sid:2001000
#
# ════════════════════════════════════════════════════════════════════
#  Alla 4 detektioner OK — Suricata-reglerna fungerar.
# ════════════════════════════════════════════════════════════════════
```

### 5.2 Save the output to your repo
```bash
./verify-detection.sh | tee ~/ais-lab2/del3/verify-output.txt
```

✅ **All 4 base rules fired = Del 3 baseline working**

---

## ✏️ STEP 6: Add Custom Rules (5 min)

### 6.1 Edit rules/ot.rules (in the sandbox)
```bash
nano ~/ais-lab2-sandboxes/del3/rules/ot.rules
# or your preferred editor
```

### 6.2 Add Rule A (FC8 Diagnostics)
Append to the end of the file:
```
alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-DIAG: Modbus Diagnostics (FC8) — potential DoS"; \
    flow:to_server,established; \
    modbus: function 8; \
    classtype:attempted-dos; \
    sid:1000100; rev:1; priority:1; \
)
```

### 6.3 Add Rule B (Unsafe Setpoint)
Append to the file:
```
alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-WRITE-CRITICAL: Setpoint > 8000 (unsafe range)"; \
    flow:to_server,established; \
    modbus: function 6, address 0, value >8000; \
    classtype:attempted-admin; \
    sid:1000101; rev:1; priority:1; \
)
```

### 6.4 Reload rules without restart
```bash
docker exec lab3-suricata suricatasc -c "reload-rules" 2>/dev/null \
  || docker restart lab3-suricata

# Wait for restart
sleep 5

# Verify rules loaded
docker logs lab3-suricata 2>&1 | grep "rules successfully loaded"
# Should show "6 rules successfully loaded" (4 base + 2 custom)
```

✅ **Rules accepted = No syntax errors**

---

## 🧪 STEP 7: Test Custom Rules (5 min)

### 7.1 Manually trigger FC6 with unsafe value
```bash
# Terminal 1: Watch for alerts
tail -F ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log

# Terminal 2: Trigger attack
docker exec lab3-jump python3 /scripts/attack-fc6.py 9999

# Expected in Terminal 1 (within 1-2 seconds):
# 05/26/2026-XX:XX:XX.XXX  [**] [1:2001000:1] OT-SESSION: New Modbus TCP...
# 05/26/2026-XX:XX:XX.XXX  [**] [1:2000006:1] OT-WRITE: Write Single Register...
# 05/26/2026-XX:XX:XX.XXX  [**] [1:1000101:1] OT-WRITE-CRITICAL: Setpoint > 8000...
```

✅ **Three alerts = FC6 + Session + Unsafe value rules firing**

### 7.2 Manually trigger FC8
```bash
# Terminal 2 (new command):
docker exec lab3-jump python3 -c "
from pymodbus.client import ModbusTcpClient
c = ModbusTcpClient('mock-plc', port=502)
c.connect()
c.diag_query_data(msg=b'\x00\x00')  # FC8
c.close()
" 2>/dev/null

# Expected in Terminal 1:
# 05/26/2026-XX:XX:XX.XXX  [**] [1:1000100:1] OT-DIAG: Modbus Diagnostics (FC8)...
```

✅ **FC8 alert fired = Diagnostic detection working**

---

## 📋 STEP 8: Collect Evidence (5 min)

### 8.1 Copy Suricata logs to your repo
```bash
cp ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log ~/ais-lab2/del3/
cp ~/ais-lab2-sandboxes/del3/rules/ot.rules ~/ais-lab2/del3/
```

### 8.2 Extract JSON alert examples (VG-bonus)
```bash
cd ~/ais-lab2-sandboxes/del3
jq 'select(.event_type=="alert") | {ts:.timestamp, sig:.alert.signature, sid:.alert.signature_id, src:.src_ip, dst:.dest_ip, modbus:.modbus}' \
  suricata-logs/eve.json | head -50 > ~/ais-lab2/del3/alert-anatomy.json
```

### 8.3 Take screenshot of fast.log
```bash
# Show last 20 alerts
tail -20 ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log

# Take screenshot and save as
# ~/ais-lab2/screenshots/fast-log-attacks.png
```

---

## 📝 STEP 9: Documentation (15-20 min)

### 9.1 Update detection.md
The template is already in `del3/detection.md`. Fill in:
- Results of detection (all tests passed?)
- Analysis of custom rules (why did they work?)
- False positive management (how would you handle noise?)
- What isn't detected (limitations)

### 9.2 Commit to git
```bash
cd ~/ais-lab2
git add del3/
git commit -m "Lab 2 Del 3: Suricata detection with custom rules - all tests passing"
git push
```

---

## ✅ FINAL CHECKLIST

- [ ] Del 2 sandbox stopped
- [ ] Del 3 sandbox started (6/6 containers)
- [ ] HMI-PLC communication verified (logs show SP/TL/PS/CL)
- [ ] Suricata health check passed (4 base rules loaded)
- [ ] verify-detection.sh passed (4/4 signatures fired)
- [ ] Custom rules added (FC8 + value matching)
- [ ] Custom rules tested (new alerts fire)
- [ ] fast.log copied to repo
- [ ] ot.rules copied to repo
- [ ] alert-anatomy.json extracted
- [ ] Screenshots taken
- [ ] detection.md updated
- [ ] Files committed to git
- [ ] verify-output.txt saved

---

## 🎉 Del 3 Complete!

You now have:
✅ Active monitoring (Suricata IDS)
✅ Detection rules (4 base + 2 custom)
✅ Alert verification (verify-detection.sh)
✅ Evidence collection (fast.log, alerts)
✅ Documentation (detection.md)

**Next:** Lab 2 Del 4 — Incident Response (May 29)

---

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Suricata won't start | Check `docker logs lab3-suricata` for rule syntax errors |
| fast.log empty | Manually trigger attack: `docker exec lab3-jump python3 /scripts/attack-fc6.py 9999` |
| HMI shows old values | Give PLC time to respond: `sleep 10` and check again |
| Memory issues | Close other apps, increase Docker memory limit |
| Port 502 conflict | `docker compose down` and try again |

---

**Estimated total time:** 60 min (30 active + 30 documentation)  
**Status:** Ready to execute  
**Date:** May 26, 2026
