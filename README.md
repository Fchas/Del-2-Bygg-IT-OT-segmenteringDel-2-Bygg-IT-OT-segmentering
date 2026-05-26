# Lab 2: Nätverks-, OT- & AI-säkerhet — IT/OT-segmentering & Detektion

**Chas Academy 2026 | Week 7 Workshop**  
**Status:** Del 2 ✅ COMPLETE | Del 3 🚀 READY TO START  
**Godkänd nivå (G) ✓ Implemented**

## 📋 Project Overview

This repository contains **Lab 2, Parts 1-3** of the industrial cybersecurity course:

**Del 1: OT-range exploration** ✅ READY
- Document OT architecture, PLC/HMI mapping, and attack surface
- Capture baseline HMI and IDS observations
- Prepare Del 1 deliverables for checkpoint

**Del 2: Network Segmentation** ✅ COMPLETE
- Identify dual-homing vulnerability
- Implement three-zone Purdue model (IT, DMZ, OT)
- Deploy bastion/jump-server pattern
- Verify with 6-test suite (all passing ✓)

**Del 3: Intrusion Detection** 🚀 READY
- Deploy Suricata IDS on OT bridge
- Create Modbus detection rules
- Test attack detection
- Document findings

## 📂 Repository Structure

```
.
├── DEL3-READY-TO-START.md              ← Read this to start Del 3
├── README.md                           ← This file
├── COMPLETION-SUMMARY.md               ← Del 2 results
├── QUICK-REFERENCE.md                  ← One-page guide
│
├── del2/                               ← Lab 2 Part 2 ✅ COMPLETE
│   ├── docker-compose.yml              (Fixed segmentation)
│   ├── verify.sh                       (6-test verification)
│   ├── verify-output.txt               (All tests passing)
│   ├── segmentation.md                 (Design doc)
│   ├── NETWORK-DIAGRAM.txt             (Network topology)
│   ├── README.md                       (Del 2 overview)
│   ├── CHECKLIST.md                    (Requirements verified)
│   └── [supporting files]
│
├── del3/                               ← Lab 2 Part 3 🚀 READY
│   ├── START-HERE.md                   ← Begin here!
│   ├── EXECUTION-GUIDE.md              (Step-by-step)
│   ├── README.md                       (Concepts)
│   ├── CUSTOM-RULES.md                 (Rule examples)
│   ├── detection.md                    (Template)
│   └── [to be populated after execution]
│
├── screenshots/                        ← Evidence collection
│   └── [screenshots of alerts]
│
└── .git/                               ← Version controlled
```

## 🎯 What Was Built

### Network Topology (3 Zones)

```
[IT Zone]  ←→ [DMZ Zone]  ←→ [OT Zone]
 Clients     Jump-server    Industrial
 Attacker    Historian      Systems
             
172.30.10.0/24  172.30.20.0/24  172.30.50.0/24
```

### Container Deployment

| Container | Network(s) | Role | IP Range |
|-----------|-----------|------|----------|
| `attacker` | IT | Threat simulation | 172.30.10.x |
| `jump-server` | IT, OT | Bastion gateway | 172.30.10.y, 172.30.50.z |
| `historian` | DMZ, OT | SCADA data collector | 172.30.20.x, 172.30.50.a |
| `mock-plc` | OT | Industrial PLC | 172.30.50.b |

### The Fix (Simple but Critical)

**Broken State:**
```yaml
attacker:
  networks:
    it:
    ot:          # ✗ BUG: Dual-homed to both IT and OT!
```

**Fixed State:**
```yaml
attacker:
  networks:
    it:          # ✓ FIXED: Only IT network
```

**Impact:** Removes direct network path from IT to OT, forcing all communication through the jump-server bastion.

## 🔐 Security Architecture

### Purdue Model Zones

| Level | Zone | Function | Segmentation |
|-------|------|----------|--------------|
| 4-5 | **IT** | Corporate systems, workstations, servers | Separate from OT |
| 3.5 | **DMZ** | Intermediary systems, historians, jump-servers | Between IT and OT |
| 0-3 | **OT** | PLCs, HMI, sensors, industrial controllers | Air-gapped from IT |

### Key Rules Enforced

1. ✅ **IT ↛ OT Direct** — BLOCKED (the fix)
2. ✅ **OT ↛ Internet** — BLOCKED (isolated)
3. ✅ **IT → Jump-server** — ALLOWED (bastion entry)
4. ✅ **Jump-server → OT** — ALLOWED (bastion function)
5. ✅ **DMZ → OT** — ALLOWED (historian reads data)
6. ✅ **DMZ → Internet** — ALLOWED (updates, NTP)

## ✅ Verification Results

All 6 critical test cases pass:

```
✓ attacker (IT) → mock-plc:502 (OT)         = BLOCKED ✓
✓ mock-plc (OT) → internet (1.1.1.1:53)     = BLOCKED ✓
✓ attacker (IT) → jump-server:22            = ALLOWED ✓
✓ jump-server → mock-plc:502 (OT)           = ALLOWED ✓
✓ historian → mock-plc:502 (OT)             = ALLOWED ✓
✓ historian → internet (1.1.1.1:53)         = ALLOWED ✓

Status: Alla 6 kontroller OK — segmenteringen är korrekt.
```

See [del2/verify-output.txt](del2/verify-output.txt) for full output.

## 📖 Implementation Files

### Core Artifacts

1. **[del2/docker-compose.yml](del2/docker-compose.yml)**
   - 4 services (attacker, jump-server, historian, mock-plc)
   - 3 isolated networks (it, dmz, ot)
   - Fixed configuration with attacker removed from OT network

2. **[del2/verify.sh](del2/verify.sh)**
   - Automated test script
   - Uses `docker exec` + `nc` for connectivity testing
   - Tests both blocked and allowed flows
   - Returns exit code 0 when all tests pass

3. **[del2/segmentation.md](del2/segmentation.md)**
   - 2-page design documentation
   - Explains identified vulnerability
   - Justifies architectural choices
   - Discusses tradeoffs and limitations
   - Includes complete rule matrix with verification evidence

4. **[del2/NETWORK-DIAGRAM.txt](del2/NETWORK-DIAGRAM.txt)**
   - ASCII network diagram showing zones
   - Container placement visualization
   - Allowed and blocked flows clearly marked
   - Docker network configuration reference

5. **[del2/README.md](del2/README.md)**
   - Folder-specific overview
   - Quick start instructions
   - Security architecture explanation
   - Bastion pattern benefits
   - Learning outcomes checklist

## 🚀 How to Use This Implementation

### Option 1: Review the Documentation
```bash
# Read the design documentation
cat del2/README.md
cat del2/segmentation.md
cat del2/NETWORK-DIAGRAM.txt
```

### Option 2: Run the Docker Lab (if Docker available)
```bash
cd del2

# Start the containerized segmentation
docker compose up -d

# Verify all containers are running
docker compose ps

# Run the segmentation tests
chmod +x verify.sh
./verify.sh

# View results
cat verify-output.txt
```

### Option 3: Manual Testing (if running)
```bash
# Test 1: Verify attacker CANNOT reach PLC directly
docker exec lab2-attacker nc -z -v -w 2 mock-plc 502
# Expected: Connection refused or timeout

# Test 2: Verify attacker CAN reach bastion
docker exec lab2-attacker nc -z -v -w 2 jump-server 22
# Expected: Connection succeeded

# Test 3: Verify bastion CAN reach OT
docker exec lab2-jump nc -z -v -w 2 mock-plc 502
# Expected: Connection succeeded
```

## 🎓 Key Concepts Demonstrated

### Docker Network Isolation
- L2 bridge network separation
- No cross-network routing by default
- Container hostname resolution within networks
- Network-level access control (no iptables needed)

### Bastion/Jump-Server Pattern
- Single point of control for sensitive access
- Enables logging and auditing of sessions
- Foundation for MFA/2FA implementation
- Prevents direct lateral movement from compromised IT systems

### Purdue Model Application
- Hierarchical zone structure (IT, DMZ, OT)
- Logical separation of concerns
- Industrial security standard (IEC 62443 aligned)
- Scalable to larger environments

### Infrastructure as Code (IaC)
- docker-compose.yml as declarative network specification
- Reproducible segmentation configuration
- Version-controllable security architecture

## 📊 Lab Requirements Checklist

### Approved Level (G) — All ✓ Complete

- ✅ **Identified the vulnerability** — Dual-homing of attacker container
- ✅ **Fixed the configuration** — Removed OT network from attacker
- ✅ **Implemented segmentation** — Three zones + bastion pattern
- ✅ **Created verification tests** — 6-test suite (all passing)
- ✅ **Documented design** — segmentation.md with rationale
- ✅ **Provided network diagram** — ASCII + Docker config reference
- ✅ **Test output as evidence** — verify-output.txt with all tests OK
- ✅ **Code committed** — docker-compose.yml tracked in git

### VG Extensions (Separate Phase)
- ⏳ Zero Trust architecture implementation
- ⏳ MFA on jump-server (SSH keys + 2FA)
- ⏳ IEC 62443 detailed risk analysis
- ⏳ Suricata IDS for protocol validation (Del 3)

## 🔒 Security Properties

### What This Lab Provides
- ✅ Network-level zone isolation
- ✅ Bastion-enforced access control
- ✅ Clear network topology
- ✅ Automated segmentation testing
- ✅ Documented security rationale

### What This Lab Does NOT Provide
- ❌ Host-based isolation (no seccomp/AppArmor)
- ❌ Container runtime security
- ❌ Active intrusion detection (IDS/IPS)
- ❌ Session recording/audit trails
- ❌ Cryptographic verification
- ❌ OT protocol validation (Modbus DPI)

These are addressed in:
- **Del 3:** Suricata IDS for active detection
- **VG-track:** Zero Trust + advanced monitoring

## 📚 Standards & References

- **Purdue Enterprise Reference Architecture (PERA)** — Industrial systems framework by ISA
- **ISA/IEC 62443** — Industrial automation security standard (zones, conduits, defense-in-depth)
- **NIST Cybersecurity Framework** — Asset identification, network segmentation
- **Docker Compose Documentation** — Network isolation mechanisms
- **CIS Controls** — Control 13: Network Segmentation

## 🔄 Lab Progression

```
Del 1: Kartläggning (Reconnaissance)      ✓ DONE
    ↓ Identified dual-homing vulnerability
Del 2: Segmentering (This Implementation) ✓ DONE
    ↓ Fixed + verified segmentation
Del 3: Detektering (IDS - Suricata)       ⏳ NEXT
    ↓ Active detection of violations
Del 4: Härdning (Hardening)               ⏳ LATER
    ↓ Advanced security measures
```

## 📝 Submission Status

**Internal Checkpoint (23 May 2026):** ✅ SUBMITTED  
**Full Lab 2 Submission (29 May 2026):** ⏳ Scheduled (includes Del 1-4 + reflection)

**Current Submission Contents:**
- ✅ Fixed docker-compose.yml
- ✅ Verification script + output
- ✅ Design documentation
- ✅ Network diagram
- ✅ Implementation README

## 🤝 Support & Questions

For issues or questions about this lab:
1. Check [del2/README.md](del2/README.md) for detailed overview
2. Review [del2/segmentation.md](del2/segmentation.md) for design rationale
3. Consult [del2/NETWORK-DIAGRAM.txt](del2/NETWORK-DIAGRAM.txt) for topology
4. Contact instructor: erkan.djafer@chasacademy.se
5. Post in course forum (support within 24h)

## 📄 License & Attribution

**Course:** Network, OT & AI Security (Chas Academy 2026)  
**Instructor:** Erkan Djafer  
**Lab Framework:** Chas Academy Labs  
**Sandbox Base:** ais-lab2-sandboxes (r87-e/ais-lab2-sandboxes)

---

## 🎯 Next Steps

### Immediate
- ✅ Lab 2 Del 2 complete (approved level)
- Prepare for Lab 2 Del 3 (Suricata IDS integration)

### Short-term (Week 8)
- Deploy Suricata on OT network (Del 3)
- Create baseline traffic profiles
- Generate detection rules for segmentation violations

### Medium-term (Week 9-10)
- Implement hardening measures (Del 4)
- Add MFA to jump-server (VG requirement)
- Complete full Lab 2 reflection

---

**Status:** ✅ APPROVED LEVEL (G) COMPLETE  
**Date Completed:** May 26, 2026  
**Next Delivery:** Del 3 — May 30, 2026

Last updated: May 26, 2026
