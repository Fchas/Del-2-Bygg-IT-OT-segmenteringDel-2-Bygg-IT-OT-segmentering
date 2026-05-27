# Lab 2 — Del 3: Intrusion Detection with Suricata

## Sammanfattning
Suricata IDS deployed on the OT network bridge (br-lab3-ot) to monitor and detect 
Modbus/TCP attacks. Four base rules provided for common attack vectors (FC5/FC6/FC16 
writes, TCP session initiation). Two custom rules added for FC8 Diagnostics detection 
and out-of-range value matching on Setpoint writes.

## Övervakad attackytan
- **Sensor:** Suricata sniffing OT bridge at L2 (promiscuous mode)
- **Protocol:** Modbus/TCP (port 502) with application-layer parsing
- **Baseline:** HMI performing FC3 reads every 1 second (legitimate)
- **Attack Surface:** Any FC5, FC6, or FC16 write command = anomaly

## Regler — översikt

### Fyra startregler (levererade)

| SID | Modbus FC | Beskrivning | Trigger | Allvarlighet |
|-----|-----------|-------------|---------|------------|
| 2001000 | — | Ny TCP-session till 502 | Varje anslutning | Medium (Priority 2) |
| 2000005 | FC5 | Force Single Coil | Disruptiv skrivning | High (Priority 2) |
| 2000006 | FC6 | Write Single Register | Setpoint-manipulation | Critical (Priority 1) |
| 2000016 | FC16 | Write Multiple Registers | Bulk-skrivning | Critical (Priority 1) |

### Två egna regler (tillagda av mig)

| SID | Modbus FC | Beskrivning | Trigger | Allvarlighet |
|-----|-----------|-------------|---------|------------|
| 1000100 | FC8 | Diagnostics — potentiell DoS | Force Listen Only Mode | Critical (Priority 1) |
| 1000101 | FC6 + Value | Unsafe Setpoint (>8000) | Värde utanför säkert intervall | Critical (Priority 1) |

## Regel-anatomi (Exempel: FC6)

```
alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-WRITE: Modbus Write Single Register (FC6)"; \
    flow:to_server,established; \
    modbus: function 6; \
    classtype:attempted-admin; \
    sid:2000006; rev:1; \
)
```

| Del | Förklaring | Betydelse |
|-----|-----------|-----------|
| `alert` | Action | Logga ett alarm (alternativ: drop, pass, log) |
| `modbus` | Protokoll | Inspektera Modbus-lagret (kräver att parser är aktiv) |
| `any any` | Source | Från vilken IP:port som helst |
| `-> $OT_NET 502` | Destination | Till OT-nätverket på port 502 |
| `msg:"..."` | Meddelande | Beskrivning som skrivs till fast.log |
| `flow:to_server,established` | Flöde | Bara paket mot server i etablerad session |
| `modbus: function 6` | App-layer | Match på Modbus-funktionskod 6 |
| `classtype:attempted-admin` | Klassificering | Kategori för alarmets prioritet |
| `sid:2000006` | ID | Unikt signaturennummer |

## Resultat av detektion

### Verifieringsresultat från `verify-output.txt`

Körning av `./verify-detection.sh` i den externa sandboxen gav följande bevis:

```
 ✓ FIRED  FC6  Write Single Register                   sid:2000006
 ✓ FIRED  FC5  Force Single Coil                       sid:2000005
 ✓ FIRED  FC16 Write Multiple Registers                sid:2000016
 ✓ FIRED  New Modbus TCP session                       sid:2001000
```

Detta visar att de fyra basreglerna för Modbus-skrivattacker och sessioninitiering fungerar korrekt.

Observera att `./verify-detection.sh` validerar de fyra levererade basreglerna (FC6, FC5, FC16 och TCP-session). De två egna reglerna för FC8 och värdebaserad setpoint-detektion är definierade i `ot.rules`, men kräver separat bevisning i `fast.log` eller `eve.json` för att bekräftas som testade.

**Bevis:**
- `del3/verify-output.txt` — verifieringsoutput från `./verify-detection.sh`
- `del3/fast.log` — den faktiska Suricata-alarmloggen som bekräftar att varje detekterad attack genererade ett larm
- `del3/ot.rules` — regelfilen som användes av Suricata för att matcha de upptäckta Modbus-paketen
- `screenshots/fast-log-attacks.png` — visuell bevisning (om tillgänglig)

## Analys: Falskt positiva vs sanna positiva

### Aktuell modell: Aggressiv (all writes = larm)

**Varför det fungerar här:**
- ✅ Ingen legitim write-trafik (bara HMI FC3-läsningar)
- ✅ 100% precision: varje write = faktiskt angrepp
- ✅ Enkelt att förstå och verifiera

**Problem i produktion:**
- ❌ Engineering-stationer gör legitima writes → storm av falska alarmer
- ❌ SOC drunknar i brus → missar riktiga attacker
- ❌ Automation-verktyg triggar dagliga alarmer

### Hantering av falskt positiva (i produktion)

1. **Allowlist per IP/MAC**
   - Känd engineering-station: 192.168.1.100 → supprimera FC6 från denna IP

2. **Tidsbaserade regler**
   - Maint-fönster: 22:00-06:00 → reducera stränghet

3. **Confidence-scoring**
   - Kombinera multiple indicators (FC6 + OOB value + suspicious timing)
   - Bara ringa alarm om score > threshold

4. **Förändringar i Suricata-regler**
   - `flow:from_client|from_server` för riktning
   - `fast_pattern` för pre-filter på låg CPU
   - `threshold` för rate-limiting

### Verifiering av sanna positiva

Varje larm i denna lab korrelerar till:
- **Källa:** lab3-jump (known attacker container)
- **Destination:** mock-plc:502 (OT PLC)
- **Funktion:** FC5/FC6/FC16 (skrivningar)
- **Värde (FC6):** 9999 (utanför säkert intervall [1000-8000])
- **Tidsstämpel:** correlerat med attack-script execution

## Vad denna detektion SKYDDAR

✅ **Direkt skrivning till PLC-register**
   - FC5 (Force Single Coil)
   - FC6 (Write Single Register)
   - FC16 (Write Multiple Registers)

✅ **Reconnaissance av port 502**
   - TCP-anslutningsförsök (SYN detection)

✅ **Denial of Service-attacker**
   - FC8 Diagnostics (Force Listen Only Mode slår av PLC:n)

✅ **Out-of-range safety violations**
   - Setpoint > 8000 (skyddsmönster för denna process)

## Vad denna detektion INTE SKYDDAR MOT

❌ **Komprometterad HMI som börjar göra FC6**
   - Ser ut som legitim trafik (samma källa som normalt)
   - Löses med: behavior-analys (sudden spike i FC6-frekvens)

❌ **Reads-baserade angrepp (data exfiltration)**
   - Passiv insamling av registerdata
   - Löses med: anomalously high read rate detection

❌ **Krypterad Modbus/TLS**
   - Vi inspekterar inte inne i TLS-paketen
   - Löses med: mutual TLS cert pinning + session analysis

❌ **Lateral rörelse inom OT**
   - PLC → HMI → annat device (vi sniffar bara till PLC)
   - Löses med: distributed sensors i alla kritiska PLC-anslutningar

❌ **Supply chain-attacker**
   - Komprometterad PLC-firmware innan deployment
   - Löses med: firmware integrity checks, secure boot, HSM

## Utökningsvägar för VG-nivå

### 1. Baslinje-learning
```bash
# Samla 24h normal-trafik
# Beräkna baseline för:
# - Antal FC3 per minut (normalt: ~60)
# - Ingen FC5/FC6/FC16 (normalt: 0)
# - Max 2-3 sessionerna per timme (normalt)

# Alarm om: FC3 < 30 eller > 100 per minut
```

### 2. Machine Learning-baserad anomali-detektion
```python
# Training: 100h normal HMI-trafik
# Features: packet_count, entropy, inter_arrival_time, fc_distribution
# Detect: Attack via isolation forest / one-class SVM
```

### 3. Protokoll-validering (DPI)
```
# Validera Modbus-PDU struktur
# Alert på:
# - Malformed packets (truncated, CRC fail)
# - Unexpected response codes
# - Out-of-spec register addresses
```

## Källor

- [Suricata Modbus Keyword Documentation](https://docs.suricata.io/en/latest/rules/modbus-keyword.html)
- ISA/IEC 62443-4-1: Detection Capabilities
- NIST Cybersecurity Framework: Detect Function
- ais-lab2-sandboxes/del3: https://github.com/r87-e/ais-lab2-sandboxes

## Nästa steg: Del 4 — Incidentrespons

När Suricata-larmen tänds i Del 3, kommer Del 4 att fokusera på:
1. **Larmanalys** — Extrahera metadata från fast.log/eve.json
2. **Incidentklassificering** — Severity, affected assets, timeline
3. **Respons-procedur** — Isolering, eradication, recovery
4. **Rapport** — ICS-CERT incident report format

---

**Status:** ✅ Detektion operationell  
**Regler testade:** 4 basregler, alla eldande  
**Egna regler:** 2 (FC8 + värdekontroll)  
**Slutförda:** 2026-05-26