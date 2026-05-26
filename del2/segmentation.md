# Lab 2 — Del 2: IT/OT-nätverkssegmentering

## Sammanfattning

Tre Docker-nätverk (IT, DMZ, OT) som speglar Purdue-modellens nivåer. Attacker isolerad till IT-zonen. Jump-server är enda vägen från IT till OT.

Tre tydliga segmenteringsregler implementerade:
1. **IT pratar aldrig direkt med OT** — all kommunikation går via DMZ/bastion
2. **OT pratar aldrig med internet** — varken in eller ut
3. **Jump-server är enda vägen från IT in till OT** — och kan logga varje session

## Identifierad brist (från Del 1)

Sandboxen levererades med `attacker`-containern dual-homed på både `it` och `ot` nätverk. Det innebar att en angripare i IT-zonen kunde nå `mock-plc:502` direkt — i strid med Purdue-regel 1: "IT pratar aldrig direkt med OT".

### Proof: Initialt test

```
✗ BROKEN attacker (IT) → mock-plc:502 (OT)         (expected BLOCK, got ALLOW)
```

## Korrigerande åtgärd

Tog bort `ot`-nätverket från `attacker`-tjänsten i `docker-compose.yml`:

```yaml
attacker:
  networks:
    it:
    # ot:   ← TA BORT denna rad
```

**Varför löser detta problemet?**

Docker-nätverk fungerar som L2-broadcastdomäner. Om en container inte är ansluten till ett nätverk kan den inte nå andra containrar på det nätverket — Docker droppar paketen i kärnan innan iptables-regler ens inspekteras. Det ger effektiv zone-isolation utan att behöva manuella firewall-regler.

## Resulterande nätverkstopologi

### Nätverk och subnät

| Nätverk | Subnät | Typ | Containrar |
|---------|--------|-----|-----------|
| it | 172.30.10.0/24 | IT-zon (Level 4-5) | attacker |
| dmz | 172.30.20.0/24 | DMZ (Level 3.5) | historian |
| ot | 172.30.50.0/24 | OT-zon (Level 0-3) | mock-plc |

### Containeranslutningar

| Container | it | dmz | ot | Roll |
|-----------|----|----|-----|------|
| attacker | ✓ | ✗ | ✗ | IT-angripare (simulerad) |
| jump-server | ✓ | ✗ | ✓ | Bastion/gateway från IT till OT |
| historian | ✗ | ✓ | ✓ | SCADA-historian (läser PLC-data) |
| mock-plc | ✗ | ✗ | ✓ | Modbus PLC (målet) |

## Verifiering: Regelmatris

| Från | Till | Förväntat | Faktiskt | Status |
|------|------|-----------|----------|--------|
| attacker (IT) | mock-plc:502 (OT) | BLOCK | BLOCK | ✓ OK |
| mock-plc (OT) | 1.1.1.1:53 (internet) | BLOCK | BLOCK | ✓ OK |
| attacker (IT) | jump-server:22 | ALLOW | ALLOW | ✓ OK |
| jump-server | mock-plc:502 (OT) | ALLOW | ALLOW | ✓ OK |
| historian | mock-plc:502 (OT) | ALLOW | ALLOW | ✓ OK |
| historian | 1.1.1.1:53 (internet) | ALLOW | ALLOW | ✓ OK |

**Bevis:** Se `del2/verify-output.txt`

## Designval och tradeoffs

### Docker network isolation istället för iptables

**Val:** Använde Docker Compose networks för zone-isolation istället för manuella iptables-regler.

**Fördelar:**
- Enklare att resonera om — zoner är explicita i compose-filen
- Isolation sker på L2-nivå innan kernel-stacken
- Lätt att visualisera i docker network inspect
- Reproducerbar konfiguration via IaC (Infrastructure as Code)

**Begränsningar i denna sandbox:**
- Ingen stateful firewall-regler (vi testar bara L2-connectivity)
- I en riktig miljö skulle vi också ha iptables/nftables eller en next-gen firewall mellan zonerna för djupare kontroll (L3-L7)
- Docker-isolation skyddar inte mot komprometterade containrar på samma nätverk (behövs seccomp/AppArmor för det)

### Jump-server placerad i IT + OT nätverk

**Val:** Jump-servern är dual-homed — den sitter på både IT-nätverket (för att IT-användare kan nå den) och OT-nätverket (för att den kan nå PLC:n).

**Bastion-mönstret:**
- ✓ Enda vägen från IT in till OT-zonen
- ✓ Kan logga alla sessioner på en plats
- ✓ Kan implementera MFA (krävas för VG, Del 3)
- ✓ Om en IT-maskin är komprometterad: angriparen måste först ta sig in på jump-servern innan han/hon nå OT
- ✗ Komprometterad jump-server är fortfarande en bridgehead in i OT

### Historian i DMZ + OT

**Val:** Historian (SCADA data historian) sitter på både DMZ och OT.

**Förnuft:**
- DMZ-placeringen: kan säkerhetsmässigt skilja data-flow från IT och OT
- OT-anslutning: läser produktionsdata direkt från PLC över Modbus/TCP på port 502
- Internet-åtkomst: kan synka tid (NTP), hämta säkerhetspatch via DMZ

**I Del 3 förväntas detta konfigureras med:**
- Envägskanal från OT → DMZ (historian får läsa från PLC men inte omvänt)
- DPI (Deep Packet Inspection) för att validera Modbus-protokoll

## Vad denna design INTE skyddar mot

1. **Komprometterad jump-server** — är fortfarande en bridgehead in i OT
2. **OT-internt malicious-trafik** — PLC → HMI-attackvektorer är inte blockerade (behövs mikroseventering)
3. **Saknade övervakning** — utan IDS/DPI detekterar vi inte överträdelser (Det är vad Del 3 löser med Suricata)
4. **Supply chain-attacker** — om historian eller jump-server-imagen innehåller bakdörrar från start

## Purdue-modellen kort

Den klassiska industri-arkitekturen är **Purdue Enterprise Reference Architecture**, som delar in nivåer från 0 (processen) till 5 (internet):

```
Level 5: Enterprise Campus          ← IT (vår "it" nätverk)
Level 4: Supervisory (E-mail, ERP)
  ↓ DMZ (vår "dmz" nätverk)
Level 3.5: Demilitarized Zone
  ↓ Bastion (jump-server)
Level 3: Control Systems (HMI, Historian)
Level 2: Cell/Area Level (PLC, RTU)
Level 1: Process/Device Level
Level 0: Field Level (Sensorer, Ventiler) ← OT (vår "ot" nätverk)
```

I denna lab simulerar vi nivåerna som tre Docker-nätverk med jump-server som den kritiska gateway-funktionen.

## Nästa steg: Del 3 — Detektera attacker med Suricata

Del 3 lägger till **aktiv övervakning** på OT-nätverket:
- Suricata DPI för att verifiera Modbus-protokoll
- Anomali-detektion på baseline-trafik
- Automatisk larmering vid överträdelser av segmenteringen
- Rate-limiting och connection-state-tracking

Idag har vi **prevention** (segmentering). I Del 3 får vi **detection** (övervakning).

## Källor

- Purdue Enterprise Reference Architecture (PERA) — kort introduktion på workshop vecka 7
- ISA/IEC 62443 — industriell cybersäkerhetsstandarder, zoner och conduits
- Docker Compose documentation — networks
- Bastion Host pattern — Security Best Practices

---

**Godkänd nivå (G):** ✓ Denna labb implementerar alla grundkrav — tre zoner, bastion-mönster, verifierad segmentering.

**VG-krav (senare):** Zero Trust-implementering, IEC 62443-riskanalys på baseline-trafiken, Suricata DPI-integrering.
