# 🎯 Lab 2 Del 3: PREPARATION COMPLETE ✅

## Summary: What's Ready

**Status:** ✅ All materials prepared and ready for execution  
**Date Prepared:** May 26, 2026  
**Time to Complete:** 60 minutes (30 active + 30 documentation)  
**Next Phase:** Execute sandbox and collect evidence

---

## 📁 Complete File Structure

### Repository Level
```
ais-lab2-repo/
├── README.md                           (Main overview)
├── COMPLETION-SUMMARY.md               (Del 2 complete)
├── QUICK-REFERENCE.md                  (One-page guide)
│
├── del2/                               (COMPLETED ✓)
│   ├── docker-compose.yml              (Fixed segmentation)
│   ├── verify.sh                       (6 tests)
│   ├── verify-output.txt               (All passing)
│   ├── segmentation.md                 (Design doc)
│   ├── NETWORK-DIAGRAM.txt             (Topology)
│   ├── README.md
│   └── CHECKLIST.md
│
├── del3/                               (READY TO START)
│   ├── START-HERE.md                   ← Read this first!
│   ├── EXECUTION-GUIDE.md              ← Step-by-step
│   ├── README.md                       ← Background
│   ├── CUSTOM-RULES.md                 ← Rule examples
│   ├── detection.md                    ← Template (fill in)
│   │
│   └── [To be populated after execution:]
│       ├── verify-output.txt           (verify-detection.sh output)
│       ├── fast.log                    (Suricata alerts)
│       ├── ot.rules                    (Custom rules)
│       └── alert-anatomy.json          (VG-bonus)
│
├── screenshots/
│   └── [To be populated:]
│       └── fast-log-attacks.png        (Alert screenshots)
│
└── .git/                               (Version controlled)
```

---

## 📚 What's Been Prepared For You

### 1. **Comprehensive Documentation** ✅

#### START-HERE.md
- Quick summary of what Del 3 is
- Pre-execution checklist
- Timeline and success criteria
- 👉 **Start here before running anything**

#### EXECUTION-GUIDE.md
- Step-by-step walkthrough (9 steps, 60 min total)
- Copy-paste ready commands
- Expected outputs at each stage
- Troubleshooting for common issues
- 👉 **Follow this while executing**

#### README.md
- Suricata concept overview
- Modbus rule anatomy explained
- What gets detected and what doesn't
- Testing procedures
- 👉 **Reference during work**

#### CUSTOM-RULES.md
- Two example custom rules
- FC8 Diagnostics (DoS detection)
- Value-based matching (Setpoint > 8000)
- Detailed comments explaining each part
- 👉 **Copy rules from here into ot.rules**

#### detection.md (Template)
- Pre-filled structure for documentation
- Table of detection rules
- Analysis sections (FP/TP, limitations, etc.)
- VG-extension ideas
- 👉 **Fill in your results here**

### 2. **Clear Concepts** ✅

**Understanding what you'll do:**
- 🐳 6-container sandbox (PLC, HMI, IDS, attacker, etc.)
- 🔍 Suricata sniffing OT bridge at L2
- 📊 Real pymodbus PLC (not mock) with register map
- 🎯 4 base rules + 2 custom rules you'll add
- 📝 verify-detection.sh automated test harness

**How to understand Suricata rules:**
- Protocol to monitor (modbus)
- 5-tuple (source, destination, port)
- Application-layer matching (Modbus function codes)
- Classification and priority levels
- Signature ID (SID) for tracking

**Why detection works here:**
- ✅ Baseline: HMI FC3 reads (legitimate)
- ❌ Anomaly: Any write (FC5/FC6/FC16) = attack
- = No false positives in this controlled environment
- = 100% detection rate for writes

### 3. **Execution Plan** ✅

**Mapped out exactly what you need to do:**

| Phase | Time | What | File |
|-------|------|------|------|
| Setup | 2 min | Stop Del 2, prep environment | EXEC-GUIDE |
| Start | 3 min | Docker compose up (6 containers) | EXEC-GUIDE |
| Verify | 4 min | HMI-PLC communication check | EXEC-GUIDE |
| Health | 2 min | Suricata startup logs review | EXEC-GUIDE |
| Test | 5 min | Run verify-detection.sh | EXEC-GUIDE |
| Extend | 5 min | Add custom rules (FC8 + value) | CUSTOM-RULES |
| Validate | 5 min | Test custom rules fire | EXEC-GUIDE |
| Collect | 5 min | Copy logs and evidence | EXEC-GUIDE |
| Document | 20 min | Write detection.md analysis | detection.md |

**Total: 51 minutes** (gives you 9 min buffer)

---

## 🚀 How to Use These Materials

### Option 1: Beginner (Follow Everything)
```
1. Read del3/START-HERE.md completely
2. Read del3/README.md for concepts
3. Read del3/CUSTOM-RULES.md to understand syntax
4. Follow del3/EXECUTION-GUIDE.md step-by-step
5. Fill in del3/detection.md with your findings
```

### Option 2: Experienced (Just Execute)
```
1. Quick scan del3/EXECUTION-GUIDE.md
2. Run commands copy-pasted from EXECUTION-GUIDE.md
3. Reference del3/CUSTOM-RULES.md when editing rules
4. Fill in del3/detection.md from observations
```

### Option 3: Stuck Anywhere
```
1. Check Troubleshooting section in EXECUTION-GUIDE.md
2. Look up concept in README.md
3. Check docker logs for actual error
4. Post error to instructor/forum
```

---

## 📊 What You'll Accomplish

### By End of Execution (60 min)

**Operational Capabilities:**
✅ Suricata IDS sniffing OT network bridge  
✅ 4 base rules detecting Modbus attacks  
✅ 2 custom rules you created detecting specific threats  
✅ Automated test suite (verify-detection.sh) passing  
✅ Alert logs collected as evidence  

**Knowledge Gained:**
✅ How IDS rules are structured and deployed  
✅ Modbus protocol attack vectors (FC5/FC6/FC16)  
✅ False positive management in detection  
✅ JSON alert format (eve.json) and parsing  
✅ How monitoring complements segmentation  

**Deliverables Collected:**
✅ verify-output.txt (automated test results)  
✅ fast.log (Suricata alert log)  
✅ ot.rules (your custom rules)  
✅ alert-anatomy.json (structured alerts)  
✅ detection.md (analysis document)  
✅ Screenshots (visual evidence)  

---

## ⚡ Quick Commands Reference

**Start sandbox:**
```bash
cd ~/ais-lab2-sandboxes/del3
docker compose up -d --build
sleep 30
docker compose ps
```

**Verify communications:**
```bash
docker logs -f lab3-hmi        # Watch HMI data
docker logs lab3-suricata      # Check IDS health
```

**Run tests:**
```bash
./verify-detection.sh          # Automated tests
tail -F suricata-logs/fast.log # Real-time alerts
```

**Collect evidence:**
```bash
cp suricata-logs/fast.log ~/ais-lab2/del3/
cp rules/ot.rules ~/ais-lab2/del3/
jq 'select(.event_type=="alert")' suricata-logs/eve.json > ~/ais-lab2/del3/alert-anatomy.json
```

**Commit results:**
```bash
cd ~/ais-lab2
git add del3/ screenshots/
git commit -m "Lab 2 Del 3: Suricata detection with custom rules"
git push
```

---

## ✅ Your Next Steps (Right Now)

### 1. **READ** (5 min)
→ Open and read `del3/START-HERE.md`

### 2. **PREPARE** (2 min)
→ Run setup commands from EXECUTION-GUIDE.md Step 1

### 3. **EXECUTE** (55 min)
→ Follow EXECUTION-GUIDE.md steps 2-8
→ Reference CUSTOM-RULES.md when editing rules
→ Reference README.md if concepts unclear

### 4. **DOCUMENT** (20 min)
→ Fill in `del3/detection.md` with results
→ Take screenshots if desired

### 5. **COMMIT** (5 min)
→ `git add del3/ screenshots/`
→ `git commit -m "..."`
→ `git push`

---

## 🎯 Success Criteria

**Del 3 is complete when:**

✅ `docker compose ps` shows 6 containers (all Up)  
✅ HMI logs show SP/TL/PS/CL values  
✅ Suricata logs show "Engine started" without errors  
✅ `./verify-detection.sh` shows all 4 base rules ✓ FIRED  
✅ You've added FC8 and value-matching rules  
✅ Custom rules test successfully  
✅ Files copied: fast.log, ot.rules, alert-anatomy.json  
✅ `del3/detection.md` is completed  
✅ All files committed to git  

---

## 📞 Support During Execution

### If commands fail:
→ Check `docker logs <container>` for error details  
→ Look up error in Troubleshooting section  

### If you don't understand something:
→ Read the concept explanation in README.md  
→ Look up specific Suricata syntax docs  

### If you get stuck:
→ Contact: erkan.djafer@chasacademy.se  
→ Post in course forum (24h response)  

### For quick reference during execution:
→ Keep EXECUTION-GUIDE.md open in one terminal  
→ Keep another terminal for running commands  

---

## 🎉 Preparation Summary

| Aspect | Status | Ready? |
|--------|--------|--------|
| Folder structure | ✅ Created | Yes |
| Documentation | ✅ 5 files | Yes |
| Setup guide | ✅ Complete | Yes |
| Execution steps | ✅ 9 steps mapped | Yes |
| Custom rules examples | ✅ 2 rules | Yes |
| Detection template | ✅ Pre-filled | Yes |
| Troubleshooting | ✅ Included | Yes |
| Sandbox config | ✅ In r87-e/ais-lab2-sandboxes/del3 | Yes |

**Everything is ready. You can start executing immediately.**

---

## 📈 Lab Progression

```
Del 1: Reconnaissance ✅ DONE
    └─ Identified dual-homing vulnerability

Del 2: Segmentation ✅ DONE
    └─ Built three-zone architecture
    └─ Implemented bastion pattern
    └─ Verified segmentation works

Del 3: DETECTION (Starting Now)
    └─ Deploy Suricata IDS ← You are here
    └─ Create detection rules
    └─ Verify alerts fire

Del 4: INCIDENT RESPONSE (May 29)
    └─ Execute response procedures
    └─ Document incident report

Final: Reflection + Submission (May 29)
    └─ Compile all parts
    └─ Submit via portal
```

---

## 🎓 What You'll Learn

After completing Del 3, you will understand:

1. **How IDS rules work** (Suricata syntax & execution)
2. **Protocol analysis** (Modbus function codes, structure)
3. **Detection engineering** (writing meaningful rules)
4. **Alert management** (false positives, confidence scoring)
5. **JSON alert format** (eve.json structure, extraction)
6. **Baseline vs anomaly** (what's normal vs attack)
7. **Limitations of detection** (what ISN'T caught)

---

## 🚀 **READY TO START**

**Current Location:** `/workspaces/Del-2-Bygg-IT-OT-segmentering/`

**Next Location:** Follow START-HERE.md  
**Then:** EXECUTION-GUIDE.md  
**Finally:** Fill in detection.md  

---

## 📋 Final Checklist

Before you start executing:

- [ ] Read del3/START-HERE.md? (Yes/No)
- [ ] Understand what you need to do? (Yes/No)
- [ ] Have ~1.5GB free RAM? (Check: `free -h`)
- [ ] Docker running? (Check: `docker ps`)
- [ ] Ready to spend ~60 minutes? (Yes/No)

**If all YES: Start now!**

---

**Date Prepared:** May 26, 2026  
**Status:** ✅ Ready for execution  
**Estimated Duration:** 60 minutes  
**Checkpoint Deadline:** May 26, 2026  
**Final Submission:** May 29, 2026

**👉 Next: Open `del3/START-HERE.md` and begin!**
