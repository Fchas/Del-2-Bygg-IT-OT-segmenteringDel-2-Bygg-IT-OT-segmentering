# HMI — Node-RED Modbus-klient

## Anslutning
- Host: 10.0.50.10
- Port: 502 (Modbus TCP standard)
- Unit ID: 1

## Polling
- Funktion: FC3 (Read Holding Registers)
- Startadress: 0
- Quantity: 4
- Polling rate: 1 sekund

## Mapping i HMI
- HR0 → Setpoint gauge
- HR1 → TankLevel gauge + trenddiagram
- HR2 → PumpSpeed gauge
- HR3 → ChlorineLevel gauge

## HMI-flöde
- Node-RED läser en bulkfråga 0..3 från PLC:n.
- Värdena delas upp och visas i dashboarden.
- Editor-vyn visar troligen en `Read 0..3 (FC3)`-nod och en Modbus-klientkonfiguration för OpenPLC.

## Observationspunkter
- HMI:n läser bara, den skriver inte till PLC:n under normal drift.
- Samma Node-RED flöde kan också avslöja att det inte finns någon autentisering mellan HMI och PLC.
- Browsing-only läge i editorn bekräftar att read-only användaren kan inspektera flödet utan att påverka processen.
