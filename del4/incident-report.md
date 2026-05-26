# ICS-CERT Incidentrapport — Lab 2 Del 4

## 1. Sammanfattning
- **Rapportdatum:** 2026-05-26
- **Rapportör:** [DITT NAMN]
- **Miljö:** Lab 2 Del 3-sandbox (lokal)
- **Incidenttyp:** Ovanliga Modbus TCP-sessioner mot PLC från OT-nod
- **Allvarlighetsgrad:** MED-HÖG
- **Påverkade system:** Mock PLC (172.31.50.10:502), HMI-polling (172.31.50.20), OT-process
- **Status:** Under analys; rekommenderad kontainment

## 2. Tidslinje (Suricata / `del4/evidence/timeline.txt`)
| Tid | Händelse |
|-----|----------|
| 05/26/2026 06:48:35 | Suricata larmade `OT-SESSION` för ny Modbus-session 172.31.50.20:48500 -> 172.31.50.10:502 |
| 05/26/2026 15:02:20 | Ny `OT-SESSION` för 172.31.50.20:41352 -> 172.31.50.10:502 |
| 05/26/2026 15:02:21 | Ny `OT-SESSION` för 172.31.50.20:41366 -> 172.31.50.10:502 |
| 05/26/2026 15:04:28 | Ny `OT-SESSION` för 172.31.50.20:48628 -> 172.31.50.10:502 |
| 05/26/2026 15:04:29 | Ny `OT-SESSION` för 172.31.50.20:48642 -> 172.31.50.10:502 |
| 05/26/2026 15:16:00 | Ny `OT-SESSION` för 172.31.50.20:35494 -> 172.31.50.10:502 |
| 05/26/2026 15:18:34 | Ny `OT-SESSION` för 172.31.50.20:48222 -> 172.31.50.10:502 |

## 3. Detektion
- **Larm-mekanism:** Suricata IDS på OT-nätbryggan (`br-lab3-ot`)
- **Triggrad SID:** 2001000 (`OT-SESSION: New Modbus TCP session`)
- **Indikation:** Upprepade nya Modbus-sessioner från HMI-pollernoden `lab3-hmi` (172.31.50.20) mot PLC `lab3-plc` (172.31.50.10)
- **Notering:** I de insamlade artefakterna fanns inga dokumenterade FC16- eller FC6-larm, vilket tyder på att det mestadels rörde sig om sessionstart eller läsning.

## 4. Påverkan
- **Integritet:** potentiell obehörig åtkomst till PLC-register via Modbus.
- **Konfidentialitet:** upprepade sessioner kan ha utgjort en informationsläcka eller kartläggning av PLC-trafik.
- **Tillgänglighet:** ingen tydlig direkt störning av PLC eller HMI dokumenterad i artefakterna, men ovanliga sessioner kan påverka OT:n om de fortsätter.
- **Kommentar:** eftersom HMI generellt initierar Modbus-läsningar, kan detta vara en indikator på antingen legitim men övervakad trafik eller ett komprometterat HMI/Historian-system.

## 5. Root cause
- Otillräcklig segmentering / tillåtlistning för Modbus TCP i OT.
- Modbus TCP saknar autentisering och kryptering.
- IDS-regeln var känslig mot nya sessioner och kan inte själv avgöra legitimitet.
- Möjlig kompromittering eller felkonfiguration av noden 172.31.50.20 (`lab3-hmi`).
- Brist på logging i HMI/jump-servern gjorde det svårt att avgöra om angriparen hade pivoterat från DMZ eller om HMI var källa.

## 6. Containment-strategi (val och motivering)
**Rekommenderad åtgärd:** Blockera den misstänkta Modbus-trafiken från `172.31.50.20` till `172.31.50.10:502` tills noden har verifierats.

**Motivering:** Det stoppade den uppenbara kommunikationen mot PLC utan att ta ner hela OT-nätet.

**Rekommenderat verktyg:** `docker network disconnect lab3-hmi del3_ot` eller en brandväggsregel mot Modbus-porten.

**Alternativ jag valde bort:**
- `docker stop lab3-hmi` — skulle kunna eliminera viktig forensisk kontext.
- Stänga ner hela OT-nätverket — skulle ta bort både övervakning och normal processfunktion.

## 7. Forensiska luckor
- `jump-history.txt` är tomt, så inga SSH-sessioner från bastionen kunde bekräftas.
- `plc-state.txt` är tomt, så inga PLC-register snapshots finns från insamlingskörningen.
- Ingen full pcap fångades i artefakterna.
- Brist på SSH-audit eller systemlogg från `lab3-hmi` gör att det är svårt att avgöra om trafikens ursprung var komprometterad.

## 8. Rekommendationer
1. **Inför en Modbus-tillåtlistning** så att endast specificerade OT-klienter får tala med PLC.
2. **Säkra HMI/jump-åtkomst med MFA och IP-allowlist**.
3. **Implementera SSH-session audit / inspelning** för bastioner och OT-accesspunkter.
4. **Utöka IDS med skriv- och konfigurationsregler** för Modbus, inte bara sessiondetektion.
5. **Isolera OT- och DMZ-trafik strikt** och begränsa lateral pivotering mellan zoner.
6. **Verifiera och uppgradera HMI/PLC-konfigurationer** för att minimera onödig Modbus-trafik.
7. **Lägg till processinterlocks i PLC** för att förhindra farliga setpoint-ändringar även om nätverk trafik når den.

## 9. Lessons learned
- En alert på en ny Modbus-session kräver omedelbar kontext; det är inte alltid en bekräftad skrivattack.
- OT-säkerhet behöver både nätverksdetektion och nodbaserad logging för att skilja legitima HMI-pollningar från misstänkt trafik.
- Undvik att ta ner systemet i onödan — isolera trafik och behåll forensiska artefakter.
- Tomma artefakter som `jump-history.txt` och `plc-state.txt` visar att insamlingsrutiner måste valideras tillsammans med analysen.

## 10. Bevis (artefakter i `del4/evidence/`)
- `fast.log` — Suricata alert-loggar
- `eve.json` — strukturerad IDS-händelselogg
- `jump-history.txt` — angiven SSH-command history (tom vid den här körningen)
- `plc-state.txt` — PLC-registertillstånd (tom vid den här körningen)
- `timeline.txt` — extrakt av viktiga Suricata-händelser
- `ot-network.json` — OT-nätverkets konfiguration vid incidenten
- `compose-state.txt` — Docker Compose-tjänsternas tillstånd vid incidenten

### Reflektion
Den här rapporten baseras på de faktiska artefakterna i `del4/evidence/`. Den starkaste slutsatsen är att vi hade ett tydligt beteende i OT-nätet, men att bevisen saknade den direkta kopplingen till en skrivattack. Det gör det extra viktigt att fortsätta analysen med mer detaljerad nodloggning och eventuellt ny insamling från `lab3-hmi` och `lab3-plc`.
