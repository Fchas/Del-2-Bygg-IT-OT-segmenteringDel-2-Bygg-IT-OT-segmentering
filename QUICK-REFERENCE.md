# Lab 2 Del 2 - Quick Reference Guide

## One-Minute Summary

**Lab:** Build IT/OT network segmentation  
**Problem:** Attacker container was dual-homed (on both IT and OT networks)  
**Solution:** Remove OT network from attacker service  
**Result:** All 6 segmentation tests pass ✅

## The Fix in 3 Lines

```yaml
# Remove this line from docker-compose.yml:
attacker:
  networks:
    it:      # Keep this
    # ot:    # DELETE THIS LINE
```

## Test the Segmentation

```bash
cd del2
docker compose up -d
./verify.sh
cat verify-output.txt
```

## What Each Container Does

| Container | Zone | Network(s) | Purpose |
|-----------|------|-----------|---------|
| **attacker** | IT | `it` only | Simulates threat in corporate network |
| **jump-server** | DMZ | `it` + `ot` | Gateway/bastion to OT (security control) |
| **historian** | DMZ | `dmz` + `ot` | SCADA historian reads production data |
| **mock-plc** | OT | `ot` only | Industrial PLC (the asset being protected) |

## Network Zones

```
┌─────────────────────────┐
│  IT (172.30.10.0/24)    │
│  - attacker             │
└────────┬────────────────┘
         │ SSH :22 (allowed)
    ╔════╧════════════════╗
    ║  jump-server        ║ (Bastion)
    ║  Bridge IT ↔ OT     ║
    ╚════╤════════════════╝
         │ Modbus :502 (allowed)
┌────────┴────────────────┐
│  OT (172.30.50.0/24)    │
│  - mock-plc             │
│  [Isolated, no internet]│
└─────────────────────────┘
```

## Six Critical Tests

```
❌ BLOCKED (must not work):
  1. attacker (IT) → mock-plc:502
  2. mock-plc (OT) → internet

✅ ALLOWED (must work):
  3. attacker (IT) → jump-server:22
  4. jump-server → mock-plc:502
  5. historian → mock-plc:502
  6. historian → internet
```

## File Purpose Guide

| File | Purpose | Details |
|------|---------|---------|
| `docker-compose.yml` | Configuration | Defines containers & networks |
| `verify.sh` | Validation | Tests all 6 segmentation rules |
| `verify-output.txt` | Evidence | Test results (all passing) |
| `segmentation.md` | Design Doc | Why & how the fix works |
| `NETWORK-DIAGRAM.txt` | Visual | Zone & flow diagram |
| `README.md` | Overview | Detailed folder guide |
| `CHECKLIST.md` | Requirements | Submission checklist |

## Key Concepts

### Docker Network Isolation
- Container only reaches other containers on same network
- No cross-network communication by default
- More effective than iptables for zone separation

### Bastion/Jump-Server Pattern
- Single point of entry to sensitive zone (OT)
- Enables logging/auditing
- Can implement MFA (future requirement)
- Prevents direct lateral movement

### Purdue Model
- **Level 4-5 (IT):** Corporate systems
- **Level 3.5 (DMZ):** Intermediary zone
- **Level 0-3 (OT):** Industrial systems
- Hierarchical security zones

## Common Questions

**Q: Why is jump-server on both IT and OT networks?**  
A: To bridge them while enforcing single point of control. IT can reach it (entry), OT can reach it (exit), but no direct IT↔OT path.

**Q: Why does historian need DMZ + OT?**  
A: Reads data from OT (needs OT), but logically sits in DMZ zone. DMZ handles data integration between zones.

**Q: How is OT isolated from internet?**  
A: OT container only has OT network interface. No route to external networks. Cannot reach host internet by design.

**Q: Can we use iptables instead?**  
A: Yes, but Docker networks are cleaner for this lab. Real environments use both.

**Q: What if jump-server is compromised?**  
A: Still a problem (still bridges zones). Next steps: hardening + monitoring (Del 3-4).

## Troubleshooting

```bash
# Check network configuration
docker network inspect lab2-del2-sandbox_it
docker network inspect lab2-del2-sandbox_dmz
docker network inspect lab2-del2-sandbox_ot

# Check which networks each container is on
docker inspect lab2-attacker | grep -A 10 Networks
docker inspect lab2-jump | grep -A 10 Networks

# Manual connectivity test
docker exec lab2-attacker ping jump-server  # Should work
docker exec lab2-attacker ping mock-plc    # Should fail (different network)

# Container logs
docker compose logs attacker
docker compose logs jump-server

# Clean up
docker compose down
```

## Submission Checklist

Before submitting, ensure:

- ✅ `docker-compose.yml` — Attacker NOT on OT network
- ✅ `verify.sh` — All 6 tests passing
- ✅ `verify-output.txt` — Evidence of passing tests
- ✅ `segmentation.md` — Design rationale explained
- ✅ `NETWORK-DIAGRAM.txt` — Clear visual layout
- ✅ `README.md` — Complete documentation

## Standards References

- **Purdue Enterprise Reference Architecture** (PERA)
- **ISA/IEC 62443** — Industrial cybersecurity standard
- **NIST CSF** — Cybersecurity framework
- **Docker Compose** — Network isolation mechanisms

## Next Steps

1. ✅ This part (Del 2) — Complete
2. ⏳ Del 3 — Add Suricata IDS for active detection
3. ⏳ Del 4 — Hardening & advanced controls
4. ⏳ Full Lab 2 submission (May 29, 2026)

## Contact

**Instructor:** Erkan Djafer (erkan.djafer@chasacademy.se)  
**Course:** Network, OT & AI Security  
**Academy:** Chas Academy 2026

---

**Version:** 1.0  
**Date:** May 26, 2026  
**Status:** Complete ✅
