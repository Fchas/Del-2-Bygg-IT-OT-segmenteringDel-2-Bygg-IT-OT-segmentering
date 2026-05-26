# Identifierad attackyta — Chas OT-range

## Protokoll-nivå
1. **Modbus saknar autentisering.** Vem som helst på OT-nätet kan skicka write-förfrågningar till PLC:n. Det finns inga credentials i Modbus-protokollet.
2. **Modbus är okrypterat.** Trafiken går i klartext, vilket gör det möjligt att avlyssna registervärden och manipulerade paketsvar.
3. **Read-trafik larmar inte.** FC3/FC1/FC2/FC4 är normala HMI-frågor och betraktas som legitima, så en angripare kan kartlägga systemet utan att trigga IDS.

## Nätverksnivå
4. **Dual-homed angriparhost.** Angriparcontainern har kontakt både mot IT och OT, vilket ger direkt nätverkstillgång till PLC:n. Detta är en tydlig segmenteringsbrist.
5. **Ingen IT/OT-firewall eller DMZ.** Det finns ingen stark gräns mellan IT och OT, bara en bridge som tillåter trafik mellan zonerna.

## Tillämpningsnivå
6. **OpenPLC använder standardinställningar.** Om PLC-konfigurationen är öppen är det troligt att standardlösenord används, vilket sänker tröskeln för obehörig åtkomst.
7. **HMI-kommunikationen till PLC är inte skriven.** Modbus-klienten skickar inga autentiseringsuppgifter och förlitar sig helt på nätverksisolering.

## Övergripande observationer
8. **Saknad audit-logg.** Det finns ingen lokal logg i PLC:n som visar vem som ändrade ett register och när.
9. **Ingen incidenthantering.** Suricata visar larm i webben, men det finns inget integrerat flöde för eskalering eller åtgärd.

## Riskrankning
| # | Risk | Sannolikhet | Konsekvens | Motivering |
|---|------|-------------|------------|------------|
| 1 | Dual-homing | Hög | Hög | Direkt access till OT från IT |
| 2 | Saknad Modbus-auth | Hög | Hög | Protokollet erbjuder ingen identitetskontroll |
| 3 | Okrypterad trafik | Medel | Medel | Kräver MITM men ger full insyn |
| 4 | Inga skrivloggar | Medel | Medel | Försvårar incidentanalys |
| 5 | Ingen IR-process | Medel | Medel | Larm fångas men ingen åtgärd är definierad |

## Sammanfattning
Det största problemet är att angriparen kan nå OT-nätet direkt och Modbus-skrivningar inte är separerade från läsningar. En angripare kan ändra Setpoint eller tvinga ventiler utan att behöva bryta HMI-pollningen.
