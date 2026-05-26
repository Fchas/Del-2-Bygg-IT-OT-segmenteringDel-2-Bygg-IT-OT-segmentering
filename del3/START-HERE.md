# Lab 2 Del 3: Intrusion Detection with Suricata — PREPARED ✅

**Status:** Ready to Execute  
**Checkpoint:** May 26, 2026  
**Files Prepared:** Complete  
**Next Action:** Start sandbox and follow execution guide

---

## 📋 What's Been Prepared

### 1. Documentation Files ✅

| File | Purpose | Status |
|------|---------|--------|
| `del3/README.md` | Overview & concepts | ✅ Complete |
| `del3/detection.md` | Design documentation template | ✅ Complete |
| `del3/EXECUTION-GUIDE.md` | Step-by-step instructions | ✅ Complete |
| `del3/CUSTOM-RULES.md` | Custom rule examples | ✅ Complete |

### 2. Directory Structure ✅

```
del3/
├── README.md                    # Overview
├── detection.md                 # Template (fill in results)
├── EXECUTION-GUIDE.md          # Step-by-step
├── CUSTOM-RULES.md             # Rule examples
├── [to be populated:]
├── verify-output.txt           # verify-detection.sh output
├── fast.log                    # Suricata alerts
├── ot.rules                    # Custom rules (copied)
└── alert-anatomy.json          # JSON alerts (VG-bonus)

screenshots/
└── fast-log-attacks.png        # Screenshots of alerts
```

### 3. Key Concepts Explained ✅

- 🎯 **Suricata Rule Anatomy** — Each component explained
- 🔍 **Modbus Protocol** — Function codes (FC5/FC6/FC8/FC16)
- 📊 **Detection Architecture** — Sensor placement, baseline traffic
- ⚠️ **False Positives** — Why we alert on ALL writes (no legit writes)
- 🚫 **Detection Limitations** — What ISN'T detected

### 4. Execution Plan ✅

**Total time:** 60 min (30 active + 30 documentation)

| Step | Time | Action |
|------|------|--------|
| 1 | 2 min | Stop Del 2, prepare environment |
| 2 | 3 min | Start Del 3 sandbox (6 containers) |
| 3 | 2 min | Verify HMI-PLC communication |
| 4 | 2 min | Confirm Suricata health |
| 5 | 5 min | Run verify-detection.sh (base rules) |
| 6 | 5 min | Add custom rules (FC8 + value) |
| 7 | 5 min | Test custom rules |
| 8 | 5 min | Collect evidence (logs, JSON) |
| 9 | 20 min | Document findings |

---

## 🚀 Quick Start (Copy-Paste Ready)

### Phase 1: Setup (5 min)
```bash
# Stop Del 2
cd ~/ais-lab2-sandboxes/del2 && docker compose down

# Start Del 3
cd ~/ais-lab2-sandboxes/del3
mkdir -p suricata-logs
docker compose up -d --build
sleep 30

# Verify
docker compose ps
```

### Phase 2: Verify (4 min)
```bash
# Check HMI-PLC communication
docker logs -f lab3-hmi
# (Ctrl+C after seeing SP/TL/PS/CL values)

# Check Suricata health
docker logs lab3-suricata 2>&1 | tail -20
```

### Phase 3: Test (5 min)
```bash
# Run base rule tests
./verify-detection.sh | tee ~/ais-lab2/del3/verify-output.txt

# Should show all 4 base rules firing ✓
```

### Phase 4: Extend (5 min)
```bash
# Edit rules/ot.rules and add:
nano rules/ot.rules

# Add FC8 and value-based rules (see CUSTOM-RULES.md)

# Reload
docker exec lab3-suricata suricatasc -c "reload-rules" || docker restart lab3-suricata
```

### Phase 5: Collect (5 min)
```bash
# Copy artifacts
cp ~/ais-lab2-sandboxes/del3/suricata-logs/fast.log ~/ais-lab2/del3/
cp ~/ais-lab2-sandboxes/del3/rules/ot.rules ~/ais-lab2/del3/

# Extract JSON alerts (bonus)
cd ~/ais-lab2-sandboxes/del3
jq 'select(.event_type=="alert") | {ts:.timestamp, sig:.alert.signature, sid:.alert.signature_id, src:.src_ip, dst:.dest_ip, modbus:.modbus}' \
  suricata-logs/eve.json > ~/ais-lab2/del3/alert-anatomy.json
```

### Phase 6: Document (20 min)
```bash
# Fill in del3/detection.md with your findings
# (Template is ready, just add your results)

# Commit everything
cd ~/ais-lab2
git add del3/ screenshots/
git commit -m "Lab 2 Del 3: Suricata detection - all tests passing"
```

---

## 📊 Expected Results

### Four Base Rules (Already in Sandbox)
```
✓ SID 2001000: New TCP session to :502        (triggered during handshake)
✓ SID 2000005: FC5 Force Single Coil          (triggered by attack-fc5.py)
✓ SID 2000006: FC6 Write Single Register      (triggered by attack-fc6.py)
✓ SID 2000016: FC16 Write Multiple Registers  (triggered by attack-fc16.py)
```

### Two Custom Rules (You Add)
```
✓ SID 1000100: FC8 Diagnostics (DoS)          (added to rules/ot.rules)
✓ SID 1000101: Unsafe Setpoint Value (>8000)  (added to rules/ot.rules)
```

### Evidence Files to Collect
```
del3/
├── verify-output.txt          # All 4 base rules fired ✓
├── fast.log                   # Suricata alert log (6 alerts/test run)
├── ot.rules                   # Your modified rules
├── alert-anatomy.json         # JSON structure of alerts (VG-bonus)
└── detection.md               # Your analysis

screenshots/
└── fast-log-attacks.png       # Screenshot of alerts (optional)
```

---

## 🔑 Key Insights

### Why We Alert on ALL Writes
```
Baseline Traffic: HMI doing FC3 (read) every second
                  No FC5, FC6, or FC16 writes

Attack Pattern:  Attacker sends FC6/FC5/FC16
                 These don't exist in baseline

Result:         100% of writes = suspicious
                No false positives in this environment
                (Production would need allowlist)
```

### What Fast.log Shows
```
Each line = one alert

[Timestamp] [**] [SID:REV] Message [**] [Classification] [Priority] {TCP} SRC:PORT -> DST:502

Example:
05/26/2026-08:30:56.723 [**] [1:2000006:1] OT-WRITE: Modbus Write Single Register (FC6) [**] 
[Classification: Attempted Administrator Privilege Gain] [Priority: 1] {TCP} 172.31.50.99:45834 -> 172.31.50.10:502
```

### Custom Rule Syntax
```
alert modbus any any -> $OT_NET 502 (
    msg:"Human readable message";
    flow:to_server,established;        # Only client→server
    modbus: function N;                # N = 5, 6, 8, 16, etc
    classtype:attempted-dos;           # Category
    sid:1000XXX; rev:1;               # Signature ID (>1000000 for custom)
)
```

---

## ✅ Pre-Execution Checklist

Before you start, verify:

- [ ] Del 2 sandbox stopped (`docker compose down` from del2)
- [ ] Docker has ~1.5GB free RAM available
- [ ] `~/ais-lab2-sandboxes/del3/` exists (cloned from r87-e/ais-lab2-sandboxes)
- [ ] `del3/docker-compose.yml` present in sandbox
- [ ] `del3/rules/ot.rules` present (4 base rules)
- [ ] `del3/verify-detection.sh` is executable
- [ ] `~/ais-lab2/del3/` folder created (already done)
- [ ] Terminal ready to execute commands

---

## 📚 Reference Materials Included

### In This Repository
- `del3/README.md` — Concepts & architecture
- `del3/EXECUTION-GUIDE.md` — Step-by-step walkthrough
- `del3/CUSTOM-RULES.md` — Example custom rules
- `del3/detection.md` — Documentation template

### External Resources
- Suricata Modbus keyword: https://docs.suricata.io/en/latest/rules/modbus-keyword.html
- IEC 62443-4-1: Detection & Response
- NIST Cybersecurity Framework: Monitor & Detect (DE)

---

## 🎯 Success Criteria

**Del 3 is complete when:**

✅ All 4 base Suricata rules fire during verify-detection.sh  
✅ Custom rules added and tested successfully  
✅ fast.log collected with alert evidence  
✅ detection.md completed with analysis  
✅ All artifacts committed to git  

**Time estimate:** 60 minutes total  
**Current status:** Ready to execute  

---

## 🚀 NEXT STEPS

### Immediate (Now)
1. Read `del3/EXECUTION-GUIDE.md` completely
2. Follow the step-by-step instructions
3. Don't skip any verification steps

### If You Get Stuck
1. Check `docker logs <container>` for errors
2. Refer to troubleshooting in EXECUTION-GUIDE.md
3. Contact instructor: erkan.djafer@chasacademy.se

### After Completion
1. Verify all artifacts in `del3/`
2. Commit to git
3. Start preparation for Del 4 (Incident Response) on May 29

---

## 📝 File Manifest

**Documentation Files (this repo):**
```
del3/README.md                  ← Concepts & background
del3/detection.md               ← Template (fill in results)
del3/EXECUTION-GUIDE.md         ← Step-by-step instructions
del3/CUSTOM-RULES.md            ← Rule examples
```

**Sandbox Files (to copy over):**
```
suricata-logs/fast.log          ← Alert log (to copy to del3/)
rules/ot.rules                  ← Custom rules (to copy to del3/)
suricata-logs/eve.json          ← Raw alerts (to extract from)
verify-detection.sh             ← Test script (run in place)
```

---

**Status:** ✅ **FULLY PREPARED FOR EXECUTION**

You're ready to start Lab 2 Del 3. Follow the execution guide step-by-step and document your findings.

**Target completion time:** 60 minutes  
**Due date:** May 26, 2026 (today - internal checkpoint)  
**Final submission:** May 29, 2026 (full Lab 2)

---

**Start now:** `cd ~/ais-lab2-sandboxes/del3` and follow `EXECUTION-GUIDE.md`
