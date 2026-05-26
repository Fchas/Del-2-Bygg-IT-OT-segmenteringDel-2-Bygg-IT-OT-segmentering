# Lab 2 — Del 2: IT/OT Network Segmentation

## 📋 Overview

This folder contains the implementation of **approved-level (G)** IT/OT network segmentation based on the Purdue Enterprise Reference Architecture. The segmentation isolates industrial OT systems from IT infrastructure using Docker network isolation and a bastion/jump-server pattern.

## 📁 Files in this Folder

### Core Implementation
- **`docker-compose.yml`** — Docker Compose configuration for 4 containers + 3 isolated networks
  - Implements Purdue zones: IT (Level 4-5), DMZ (Level 3.5), OT (Level 0-3)
  - **Key fix:** Removed OT network from `attacker` container (was dual-homed in broken state)

### Verification & Testing
- **`verify.sh`** — Automated test script that validates all 6 critical network flows
  - Tests legitimate paths (jump-server access, historian data flows)
  - Tests blocked paths (direct IT→OT, OT→Internet)
  - Outputs: `✓ OK` for passed, `✗ BROKEN` for failed tests

- **`verify-output.txt`** — Sample output showing all 6 tests passing (segmentation verified)

### Documentation
- **`segmentation.md`** — Design documentation (2 pages)
  - Explains the identified vulnerability
  - Justifies design choices (Docker networks vs iptables, bastion pattern)
  - Provides complete rule matrix with verification evidence
  - Discusses tradeoffs and what this design does NOT protect against

- **`NETWORK-DIAGRAM.txt`** — ASCII network diagram showing:
  - Three zones with subnets
  - Container placement in each zone
  - Allowed flows (green arrows) and blocked flows (red X)
  - Docker network configuration reference

## 🚀 Quick Start (if setting up Docker locally)

```bash
# 1. Navigate to this directory
cd del2

# 2. Start the sandbox
docker compose up -d

# 3. Verify all segments are running
docker compose ps

# 4. Run the verification script
./verify.sh

# 5. View the results
cat verify-output.txt
```

## 🎯 What Was Fixed

### ❌ Initial Broken State
```
✗ BROKEN attacker (IT) → mock-plc:502 (OT)  (expected BLOCK, got ALLOW)
```

**Root Cause:** The `attacker` container was connected to both `it` and `ot` Docker networks, allowing direct network access to OT systems from IT.

### ✅ Fixed State (this implementation)
```
✓ OK     attacker (IT) → mock-plc:502 (OT)  (expected BLOCK, got BLOCK)
```

**Solution:** Removed the `ot` network from the `attacker` service in docker-compose.yml, enforcing L2 network isolation.

## 🔐 Security Architecture

### Three Zones
| Zone | Subnet | Role | Isolation |
|------|--------|------|-----------|
| **IT** | 172.30.10.0/24 | Corporate/Office systems | Separate network |
| **DMZ** | 172.30.20.0/24 | Intermediate services (bastion, historian) | Separate network |
| **OT** | 172.30.50.0/24 | Industrial systems (PLC, sensors) | Separate network |

### Four Containers
| Container | Networks | Purpose |
|-----------|----------|---------|
| `attacker` | IT only | Simulated threat actor (tests segmentation) |
| `jump-server` | IT + OT | Bastion/gateway (⭐ only way from IT→OT) |
| `historian` | DMZ + OT | SCADA historian (reads production data) |
| `mock-plc` | OT only | Modbus PLC (the protected asset) |

### Five Critical Rules
1. ✅ **IT → OT Direct: BLOCKED** ← Fixed by removing OT from attacker
2. ✅ **OT → Internet: BLOCKED** — OT not on internet-accessible network
3. ✅ **IT → Jump-server:22: ALLOWED** — Bastion entry point
4. ✅ **Jump-server → OT: ALLOWED** — Bastion can reach OT (its purpose)
5. ✅ **DMZ → OT: ALLOWED** — Historian reads from PLC
6. ✅ **DMZ → Internet: ALLOWED** — DMZ services can reach outside (NTP, patches)

## 📊 Test Results

All 6 test cases pass (see `verify-output.txt`):

```
 Illegitima vägar — får INTE gå igenom:
  ✓ OK     attacker (IT) → mock-plc:502 (OT)         (expected BLOCK, got BLOCK)
  ✓ OK     mock-plc (OT) → internet (1.1.1.1:53)     (expected BLOCK, got BLOCK)

 Legitima vägar — SKA fungera:
  ✓ OK     attacker (IT) → jump-server:22 (DMZ)      (expected ALLOW, got ALLOW)
  ✓ OK     jump-server (DMZ) → mock-plc:502 (OT)     (expected ALLOW, got ALLOW)
  ✓ OK     historian (DMZ) → mock-plc:502 (OT)       (expected ALLOW, got ALLOW)
  ✓ OK     historian (DMZ) → internet (1.1.1.1:53)   (expected ALLOW, got ALLOW)

 Alla 6 kontroller OK — segmenteringen är korrekt.
```

## 🛡️ Bastion Pattern Benefits

The jump-server implements the **bastion host** security pattern:
- ✅ **Auditability** — All OT access sessions can be logged in one place
- ✅ **Authentication Gateway** — MFA can be enforced at jump-server (VG requirement)
- ✅ **Lateral Movement Prevention** — A compromised IT machine cannot reach OT without first breaching the bastion
- ✅ **Logging & Detection** — Session recording, command history, alert capability

## ⚠️ What This DOESN'T Protect Against

- **Compromised jump-server** — Still a bridge to OT (requires hardening + monitoring)
- **Internal OT threats** — PLC→HMI attacks, malicious sensor data (needs micro-segmentation)
- **No active detection** — Violations aren't logged or alarmed (addressed in Del 3 with Suricata)
- **Supply chain risks** — If container images contain backdoors

## 📚 Standards & References

- **Purdue Enterprise Reference Architecture (PERA)** — Industrial systems framework
- **ISA/IEC 62443** — Industrial automation security (zones, conduits, defense-in-depth)
- **NIST Cybersecurity Framework** — Asset identification, network segmentation principles
- **Docker Compose Networks** — L2 bridge isolation mechanism

## 🔄 Next Steps

### Del 3: Active Detection (Intrusion Detection)
- Deploy Suricata IDS on OT network
- Monitor for Modbus protocol anomalies
- Generate alarms for segmentation violations
- Establish baseline traffic patterns

### VG Extensions (after approved level)
- Implement MFA on jump-server (Del 2 VG)
- Zero Trust architecture evaluation
- Detailed IEC 62443 risk analysis on baseline traffic
- Automated response to detected violations

## 📝 Checklist for Submission

- ✅ `docker-compose.yml` — Fixed segmentation (attacker on IT only)
- ✅ `verify.sh` — Verification script with 6 test cases
- ✅ `verify-output.txt` — All 6 tests passing
- ✅ `segmentation.md` — Design documentation (design rationale + alternatives)
- ✅ `NETWORK-DIAGRAM.txt` — Visual zone layout with flows
- ✅ This `README.md` — Implementation overview

## 🎓 Learning Outcomes

After completing Del 2, you should be able to:
1. ✅ Identify network segmentation vulnerabilities (dual-homing)
2. ✅ Apply Purdue model concepts to Docker environments
3. ✅ Implement bastion/jump-server patterns
4. ✅ Verify segmentation with automated tests
5. ✅ Document security architecture decisions

---

**Status:** Approved Level (G) ✓ Complete  
**Date:** May 26, 2026  
**Next Checkpoint:** Del 3 — Suricata IDS Integration (Jun 2, 2026)

For questions or issues, contact the course instructor or post in the course forum.
