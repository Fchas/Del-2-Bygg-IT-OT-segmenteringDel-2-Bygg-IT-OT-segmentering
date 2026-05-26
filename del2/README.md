# Lab 2 — Del 2: IT/OT Network Segmentation

## 📋 Overview

Denna mapp innehåller Del 2-implementeringen av IT/OT-segmentering i labbet.
Konfigurationen använder Docker Compose för att skapa tre isolerade nätverk enligt Purdue-modellen:
- IT (`lab2-del2-sandbox_it`)
- DMZ (`lab2-del2-sandbox_dmz`)
- OT (`lab2-del2-sandbox_ot`)

## 📁 Filer i denna mapp

### Kärnimplementation
- **`docker-compose.yml`** — Skapar fyra containrar och tre Docker-nätverk.
  - `attacker` är kopplad endast till IT-nätverket.
  - `jump-server` är kopplad till IT och OT som bastion.
  - `historian` är kopplad till DMZ och OT.
  - `mock-plc` är kopplad endast till OT.

### Verifiering
- **`verify.sh`** — Kontrollerar 6 kritiska nätverksflöden.
- **`verify-output.txt`** — Exempel på godkänt resultat.

### Dokumentation
- **`segmentation.md`** — Designmotivering, arkitektur, hotbild och verifiering.
- **`NETWORK-DIAGRAM.txt`** — ASCII-diagram över zoner, subnet och flöden.

## 🛠 Aktuell konfiguration i `docker-compose.yml`

### Nätverk
- `lab2-del2-sandbox_it` → 172.30.10.0/24
- `lab2-del2-sandbox_dmz` → 172.30.20.0/24
- `lab2-del2-sandbox_ot` → 172.30.50.0/24

### Containrar
- `lab2-attacker` (`attacker`) — IT only
- `lab2-jump` (`jump-server`) — IT + OT
- `lab2-historian` (`historian`) — DMZ + OT
- `lab2-plc` (`mock-plc`) — OT only

## 🚀 Snabbstart

```bash
cd del2
docker compose up -d
docker compose ps
./verify.sh
cat verify-output.txt
```

## 🎯 Vad som är fixat

### Ursprungligt problem
`attacker` hade tidigare åtkomst till både IT och OT, vilket gav en direkt väg till PLC:n.

### Fix
`attacker` är nu ansluten endast till IT-nätverket. Detta stänger den direkta vägen till OT och förhindrar enkel lateral pivotering.

## ✅ Kontrollmål

### Legitima vägar som ska fungera
- `attacker` (IT) → `jump-server` (DMZ):22
- `jump-server` (DMZ) → `mock-plc` (OT):502
- `historian` (DMZ) → `mock-plc` (OT):502
- `historian` (DMZ) → internet:53

### Otillåtna vägar som ska blockeras
- `attacker` (IT) → `mock-plc` (OT):502
- `mock-plc` (OT) → internet:53

## 📊 Testresultat

Den aktuella implementeringen förväntas få alla 6 tester godkända. Se `verify-output.txt` för verifiering.

## 🔐 Arkitektur

### Zoner
| Zon | Subnet | Roll |
|-----|--------|------|
| IT | 172.30.10.0/24 | Angripare / företagsnät |
| DMZ | 172.30.20.0/24 | Bastion / historian |
| OT | 172.30.50.0/24 | PLC / industriell utrustning |

### Säkerhetsprinciper
- IT och OT är separerade i olika Docker-nätverk.
- Endast `jump-server` får kommunicera mot OT.
- `historian` kan läsa data från OT men ligger i DMZ.
- Direkt IT→OT-åtkomst är blockerat.

## ⚠️ Begränsningar
- Komprometterad bastion är fortfarande en risk.
- Detta är en isoleringslösning, inte ett komplett detektionssystem.
- Applikationsskydd och autentisering ingår inte i denna del.

## 📌 Slutsats
Del 2 är klart för inlämning när:
- `docker compose up -d` startar alla tjänster
- `./verify.sh` passerar alla 6 tester
- `verify-output.txt` visar `✓ OK` för samtliga tester
- `segmentation.md` och `NETWORK-DIAGRAM.txt` stämmer överens med implementationen

**Status:** Klart för godkännande i Del 2.
