# Lab 2 Del 1: OT Arkitektur och attackyta

## Översikt
Denna mapp innehåller Del 1-analysen av OT-arkitekturen, segmentering och attackyta för labben.
Det är en dokumentationsleverans som beskriver den simulerade vattenreningsanläggningen, dess Modbus-kommunikation och de största säkerhetsbristerna.

## Innehåll
- `architecture.md` — Arkitektur och nätverkslayout
- `attack-surface.md` — Identifierad attackyta och riskranking
- `hmi-notes.md` — HMI-implementation och Modbus-polling
- `plc-notes.md` — PLC-registerkarta, logik och potentiella attacker

## Viktiga observationer
- HMI:n läser PLC:n med **Modbus TCP FC3** varje sekund, vilket innebär att trafikmönstret är läsorienterat.
- Modbus-kommunikationen är **okrypterad och utan autentisering**.
- `lab2-attacker` är dual-homed i Del 1-analysen, vilket ger möjlighet till direkt OT-åtkomst.
- Det finns ingen tydlig IT/OT-firewall eller DMZ i den analys som beskrivs här.
- PLC-register som `HR0` (Setpoint) kan skrivas av en angripare om denne når OT-nätverket.

## Nätverksstruktur enligt analysen
- `br-ot` / 10.0.50.0/24: PLC + HMI
- `br-it` / 10.0.10.0/24: angripare och IT-nät
- HMI:n är dual-homed och har kontakt med både IT och OT i analysen.

## Syfte
Denna leverans dokumenterar:
1. Arkitektur och gränssnitt mellan IT/OT
2. Sårbarheter i Modbus och segmentering
3. HMI- och PLC-beteenden
4. Vilka risker som bör adresseras i Del 2 och Del 3

## Användning
1. Läs `architecture.md` för helhetsbilden.
2. Läs `attack-surface.md` för riskanalysen.
3. Använd `hmi-notes.md` och `plc-notes.md` för teknisk detaljinformation.
4. Referera tillbaka till denna README vid inlämning för att visa att Del 1 är komplett.
