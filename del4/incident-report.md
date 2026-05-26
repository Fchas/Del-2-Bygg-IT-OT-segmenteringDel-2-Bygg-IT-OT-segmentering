# ICS-CERT Incidentrapport — Lab 2 Del 4

## 1. Sammanfattning
- **Rapportdatum:** 2026-05-26
- **Rapportör:** [DITT NAMN]
- **Miljö:** Lab 2 Del 3-sandbox (lokal)
- **Incidenttyp:** Obehörig processmanipulering via Modbus TCP från komprometterad bastion
- **Allvarlighetsgrad:** HÖG
- **Påverkade system:** Mock PLC (172.31.50.10:502), HMI-polling, OT-process
- **Status:** Löst, root cause identifierad

## 2. Tidslinje (UTC)
| Tid | Händelse |
|-----|----------|
| T+0 | Angripare initierar nmap-scan från jump-server |
| T+15s | FC16 bulk-write till HR0..3 (Suricata sid:2000016) |
| T+25s | FC6 maskering — Setpoint=5500 (sid:2000006) |
| T+1m | IR-person upptäcker larmkaskaden i `fast.log` |
| T+1m30s | Triage: angripar-IP 172.31.50.20 bekräftad |
| T+2m | Nödåterställning: Setpoint återställd till 5000 |
| T+2m15s | Containment: jump-server isolerad från OT-nätet |
| T+5m | Evidence-insamling klar |
| T+8m | Recovery via historian — process tillbaka i normaldrift |
| T+12m | Eradicate: jump-server rebuildad och återansluten |

## 3. Detektion
- **Larm-mekanism:** Suricata IDS på OT-nätbryggan (`br-lab3-ot`)
- **Triggrade SID:** 2001000 (ny session), 2000016 (FC16), 2000006 (FC6)
- **Detektionstid:** Utifrån labbens schema, larmen dök upp omedelbart vid attackens start
- **Fenomen:** kaskad av Modbus-skrivoperationer och sessioner från jump-servern

## 4. Påverkan
- **Processäkerhet:** Setpoint höjdes till 9999 under en kort period innan maskering sattes till 5500. I denna sandbox gav det inga fysiska följder, men i en riktig process kunde det leda till överfyllnad eller pumpstress.
- **Tillgänglighet:** Jump-servern isolerades temporärt från OT-nätet, men PLC och HMI fortsatte att fungera.
- **Konfidentialitet:** Angriparens aktivitet inkluderade en nätverksskanning mot OT-zone, vilket visar att angriparen kunde kartlägga nätverket. Modbus-läsningar var inte larmade och kunde avslöja processdata.
- **Integritet:** PLC-register HR0..3 och alarm-coil manipulerades. Dessa värden återställdes genom kontrollerad recovery.

## 5. Root cause
- Komprometterade SSH-uppgifter för jump-servern (simulerat i labben)
- Ingen MFA eller IP-allowlist på bastionen
- Ingen session-recording eller SSH-audit på jump-servern
- Modbus TCP saknar inbyggd autentisering och kryptering
- Proxy- eller tillståndsbaserad åtkomstkontroll saknades mellan DMZ och OT

## 6. Containment-strategi (val och motivering)
**Vald åtgärd:** `docker network disconnect lab2-del3-sandbox_ot lab3-jump`

**Motivering:** Detta var en "soft kill" som stängde angriparens väg till OT utan att stänga ner jump-serverns maskinvara och processminne. HMI och Historian förblev online, vilket bevarade övervakning och möjliggjorde vidare forensisk analys.

**Alternativ jag valde bort:**
- `docker stop lab3-jump` — skulle radera bash-historik och processlista
- Stänga OT-nätet helt — skulle ha stoppat HMI-pollern och tagit bort insyn i processen

## 7. Forensiska luckor
- Ingen fullständig pcap finns i labbmiljön; endast alert-triggred trafik sparas av Suricata
- Ingen audit-logg från PLC eftersom Modbus-protokollet inte ger sådan loggning
- Jump-servern loggar inte SSH-sessioner i sandlådans konfiguration
- Inga autentiska användaridentitetsloggar finns, vilket gör det svårt att skilja angripare från legitima användare

## 8. Rekommendationer
1. **Inför MFA på jump-servern** för att skydda mot stulna credentials
2. **IP-allowlist för SSH och jump-access** — endast tillåt kända IT-noder
3. **Session recording och audit** för alla SSH-sessions till bastionen
4. **Modbus write-allowlist** i IDS/säkerhetsgateway — endast legitim professoriserad skrivkälla får skriva
5. **Lägg till FC8 och recon-regler** (sid 1000100, 1000200) i Suricata
6. **Inför OT-druppar/kill switch** för automatisk isolering vid kritisk alert
7. **Tillägg av process-side interlocks** i PLC:en, exempelvis intern begränsning av Setpoint > 8000

## 9. Lessons learned
- Detection är nödvändigt men inte tillräckligt; IDS visade attacken men kunde inte stoppa den själv
- I OT är det viktigare att säkra processen först än att isolera systemet hastigt
- ``docker network disconnect`` är en bra OT-specifik containment-åtgärd eftersom den bevarar forensisk data
- En svarstid om 2–3 minuter kan vara för lång i ett produktionssystem; automation och playbooks behövs

## 10. Bevis (artefakter i `del4/evidence/`)
- `fast.log` — Suricata alert-loggar
- `eve.json` — strukturerad IDS-händelselogg
- `jump-history.txt` — angriparens kommandon från bastionens history
- `plc-state.txt` — PLC-registertillstånd vid containment
- `timeline.txt` — extrakt av viktiga Suricata-händelser
- `ot-network.json` — OT-nätverkets konfiguration vid incidenten
- `compose-state.txt` — Docker Compose-tjänsternas tillstånd vid incidenten

### Reflektion
När denna incident rapporteras ska tidslinjen och de exakta IP-adresserna matchas mot de faktiska loggarna i `del4/evidence/`. Målet är att ge en komplett bild av attacken, hur den stoppades, och vad som krävs för att hindra den nästa gång.
