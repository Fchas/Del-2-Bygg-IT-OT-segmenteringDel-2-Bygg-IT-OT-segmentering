# PLC — water_treatment.st (sammanfattning)

## Adresskarta
| Tag | Modbus | Variabel | Init |
|-----|--------|----------|------|
| %QW0 | HR0 | Setpoint | 5000 |
| %QW1 | HR1 | TankLevel | 3000 |
| %QW2 | HR2 | PumpSpeed | (styrs av logik) |
| %QW3 | HR3 | ChlorineLevel | (styrs av logik) |
| %QX0.0 | Coil 0 | DosingValve | (on/off) |
| %QX0.1 | Coil 1 | Alarm | (on/off) |

## Logik (sammanfattning på 3 rader)
1. Om TankLevel < Setpoint, öka pumpen för att fylla tanken.
2. Om ChlorineLevel < 300, öppna doseringsventilen för att öka klorhalten.
3. Om TankLevel > Setpoint + 2000, aktivera alarmet.

## Säkerhetsobservationer
- Setpoint är ett vanligt holding register (HR0) och kan skrivas om med FC6. Inget skrivskydd syns i protokollet.
- Larmet är reaktivt: det går igång först när tanknivån redan har överskridit en farozon.
- Klor-doseringslogiken kontrolleras med en enstaka coil, vilket innebär att en write-funktion kan manipulera ventilen direkt.
- PLC:n saknar autentiseringslager utöver nätverksseparation, så en angripare som når OT kan styra processvärden.

## Attackidéer från PLC-logiken
- Skriv 9999 till HR0 (Setpoint) för att tvinga pumpen att fylla till en ovanligt hög nivå.
- Tvinga Coil 1 (Alarm) till TRUE för att skapa falska incidenter.
- Skriv ett extremt lågt värde till HR3 för att stänga av kloreringen felaktigt.
