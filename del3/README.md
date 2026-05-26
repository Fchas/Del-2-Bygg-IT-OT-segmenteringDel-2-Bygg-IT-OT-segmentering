# Lab 2 Del 3: Intrusion Detection with Suricata IDS

**Status:** Ready to Start  
**Date:** May 26, 2026  
**Checkpoint Deadline:** May 26, 2026  
**Final Submission:** May 29, 2026

## 📋 Del 3 Overview

After building network segmentation in Del 2, we now add **active monitoring and detection**:
- Deploy Suricata IDS on OT network bridge
- Monitor for suspicious Modbus commands
- Create custom detection rules
- Verify alerts fire on attacks
- Document detection findings

## 🎯 What You'll Build

| Component | Purpose | Details |
|-----------|---------|---------|
| **Suricata IDS** | Intrusion Detection | Sniffs OT bridge (br-lab3-ot) |
| **4 Base Rules** | Attack Detection | FC5, FC6, FC16, TCP SYN |
| **2 Custom Rules** | Enhanced Detection | FC8 Diagnostics + Value Matching |
| **Test Harness** | Verification | verify-detection.sh script |

## 🚀 Quick Start Sequence

### Step 1: Prepare Environment
```bash
# Stop Del 2 sandbox if running
cd ~/ais-lab2-sandboxes/del2
docker compose down

# Navigate to Del 3
cd ~/ais-lab2-sandboxes/del3
mkdir -p suricata-logs
```

### Step 2: Start Del 3 Sandbox (6 containers)
```bash
# Build and start (first time: ~1-2 min for pip install)
docker compose up -d --build

# Verify all 6 containers running
docker compose ps
```

**Expected Containers:**
- `lab3-mock-plc` — Real pymodbus PLC (port 502)
- `lab3-hmi` — HMI poller (FC3 every 1s)
- `lab3-attacker` — Attack simulation container
- `lab3-jump` — Jump-server with attack scripts
- `lab3-historian` — SCADA historian
- `lab3-suricata` — Suricata IDS (monitoring)

### Step 3: Verify HMI-PLC Communication
```bash
# Watch HMI polling the PLC
docker logs -f lab3-hmi
# Should show: [HMI] SP=5000 TL=3050 PS=80 CL=495
# Ctrl+C to stop
```

### Step 4: Confirm Suricata is Monitoring
```bash
# Check Suricata startup logs
docker logs lab3-suricata 2>&1 | tail -20

# Look for:
# - "4 rules successfully loaded"
# - "3 inspect application layer"
# - "br-lab3-ot: creating 2 threads"
# - "Engine started"
```

### Step 5: Run Detection Verification
```bash
# Run automated test
./verify-detection.sh

# Save output
./verify-detection.sh | tee ~/ais-lab2/del3/verify-output.txt
```

### Step 6: Create Custom Rules
Edit `rules/ot.rules` and add two new rules:

**Rule A: FC8 Diagnostics (DoS)**
```
alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-DIAG: Modbus Diagnostics (FC8) — potential DoS"; \
    flow:to_server,established; \
    modbus: function 8; \
    classtype:attempted-dos; \
    sid:1000100; rev:1; priority:1; \
)
```

**Rule B: Unsafe Setpoint Value**
```
alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-WRITE-CRITICAL: Setpoint > 8000 (unsafe range)"; \
    flow:to_server,established; \
    modbus: function 6, address 0, value >8000; \
    classtype:attempted-admin; \
    sid:1000101; rev:1; priority:1; \
)
```

### Step 7: Collect Evidence
```bash
# Copy Suricata logs to repo
cp ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log ~/ais-lab2/del3/
cp ~/ais-lab2-sandboxes/del3/rules/ot.rules ~/ais-lab2/del3/

# Extract alert JSON (VG-bonus)
cd ~/ais-lab2-sandboxes/del3
jq 'select(.event_type=="alert") | {ts:.timestamp, sig:.alert.signature, sid:.alert.signature_id, src:.src_ip, dst:.dest_ip, modbus:.modbus}' \
  suricata-logs/eve.json | head -30 > ~/ais-lab2/del3/alert-anatomy.json
```

### Step 8: Document Findings
Write `del3/detection.md` using the template provided below.

---

## 📁 Files You'll Create in del3/

```
del3/
├── detection.md              ← Design documentation
├── verify-output.txt         ← verify-detection.sh results
├── fast.log                  ← Suricata alerts (copied)
├── ot.rules                  ← Your custom rules (copied)
├── alert-anatomy.json        ← Example alert JSON (VG-bonus)
└── [screenshots/]            ← Screenshots of alerts
    └── fast-log-attacks.png
```

---

## 🔍 Understanding Suricata Rules

### Rule Anatomy (Example: FC6 Write Single Register)

```
alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-WRITE: Modbus Write Single Register (FC6)"; \
    flow:to_server,established; \
    modbus: function 6; \
    classtype:attempted-admin; \
    sid:2000006; rev:1; \
)
```

| Part | Meaning |
|------|---------|
| `alert` | Action (alert/drop/log/pass) |
| `modbus` | Protocol to inspect |
| `any any` | From any IP:port |
| `-> $OT_NET 502` | To OT network on port 502 |
| `msg:...` | Human-readable description |
| `flow:to_server,established` | Only match client→server in established sessions |
| `modbus: function 6` | Trigger on Modbus function code 6 |
| `classtype:attempted-admin` | Category for alert |
| `sid:2000006` | Signature ID (unique identifier) |

### Why We Alert on ALL Writes

In this environment:
- ✅ Legitimate traffic: HMI polling with **FC3 (reads only)**
- ❌ Illegitimate traffic: **Any write command (FC5/FC6/FC16)**

→ Therefore: **Every write is per definition suspicious**

In production, you'd maintain an allowlist of authorized writers and only alert on exceptions.

---

## 🎯 The Four Base Rules (Already Provided)

| SID | Function | Command | Severity | Why? |
|-----|----------|---------|----------|------|
| 2001000 | TCP SYN | New connection to :502 | Medium | Detect reconnaissance |
| 2000005 | FC5 | Force Single Coil | High | Disruptive write |
| 2000006 | FC6 | Write Single Register | High | Setpoint manipulation |
| 2000016 | FC16 | Write Multiple Registers | Critical | Bulk write attack |

---

## 🧪 Testing Your Setup

### Manual Test: Attack FC6
```bash
# Terminal 1: Watch alerts
tail -F ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log

# Terminal 2: Trigger attack
docker exec lab3-jump python3 /scripts/attack-fc6.py 9999

# Expected: Two alerts in Terminal 1
# - SID 2001000: New TCP session
# - SID 2000006: FC6 write detected
```

### Full Test Suite
```bash
cd ~/ais-lab2-sandboxes/del3
./verify-detection.sh

# Expected output:
#  ✓ FIRED  FC6  Write Single Register           sid:2000006
#  ✓ FIRED  FC5  Force Single Coil               sid:2000005
#  ✓ FIRED  FC16 Write Multiple Registers        sid:2000016
#  ✓ FIRED  New Modbus TCP session               sid:2001000
```

---

## 📝 Template: detection.md

Save this as `del3/detection.md`:

```markdown
# Lab 2 — Del 3: Intrusion Detection with Suricata

## Sammanfattning
Suricata IDS deployed on OT network bridge. Monitors all Modbus traffic
and alerts on writes (FC5/FC6/FC16) and session initiation. Added two
custom rules: FC8 Diagnostics detection + unsafe setpoint value matching.

## Detection Architecture
- **Sensor Placement:** Suricata sniffing br-lab3-ot (OT bridge)
- **Protocol Coverage:** Modbus/TCP application layer (port 502)
- **Baseline Traffic:** HMI polling every 1 second (FC3 read only)
- **Attack Surface:** Any write command = anomaly

## Rule Set

### Base Rules (Provided)
| SID | Type | Message | Detection |
|-----|------|---------|-----------|
| 2001000 | TCP | New Modbus session | Reconnaissance |
| 2000005 | FC5 | Force Single Coil | Disruptive write |
| 2000006 | FC6 | Write Single Register | Setpoint manipulation |
| 2000016 | FC16 | Write Multiple Registers | Bulk write |

### Custom Rules (Added by Me)
| SID | Type | Message | Detection |
|-----|------|---------|-----------|
| 1000100 | FC8 | Diagnostics — potential DoS | Denial of service |
| 1000101 | FC6+Value | Unsafe setpoint (>8000) | Out-of-range safety |

## Detection Results

All attacks successfully detected:
- ✓ FC6 write attack (Setpoint manipulation) — SID 2000006
- ✓ FC5 attack (Force coil) — SID 2000005
- ✓ FC16 attack (Multiple register write) — SID 2000016
- ✓ TCP session initiation — SID 2001000

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
