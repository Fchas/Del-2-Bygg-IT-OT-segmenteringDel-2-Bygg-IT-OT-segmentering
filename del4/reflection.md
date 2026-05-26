# Del 4 Reflektion — OT-säkerhet i praktiken

Den här labben visar tydligt hur OT-säkerhet skiljer sig från IT-säkerhet på tre konkreta sätt:

1. Processprioritering framför systemisolering.
   - I IT är standard ofta att isolera eller stänga ner en infekterad host. I OT kan det innebära att en process fortsätter utan övervakning, vilket kan vara farligare än själva intrånget. I den här labben valde jag därför att isolera jump-servern från OT-nätet istället för att stoppa PLC eller HMI.
2. Fysisk processåterställning är en del av recovery.
   - Återställning i OT handlar inte bara om att återställa filer och patcha system, utan också om att få registervärden och setpoint tillbaka till säkra standarder. Den kontrollerade återställningen via historian visar det: `Setpoint=5000` och `Alarm=False` är lika viktiga som att återupprätta nätverksanslutning.
3. Begränsade forensiska signaler.
   - OT-protokoll som Modbus ger ingen inbyggd audit-logg, och i labben saknades full pcap samt SSH-session-logging. Det gör att man i OT ofta jobbar med betydligt fler luckor och måste kompensera med nätverksövervakning och kontrollerade bastioner.

Av Del 1–4 var Del 4 den mest insiktsfulla. Den kändes samtidigt mest realistisk eftersom den tvingade mig att tänka som en SOC-analytiker: identifiera händelsen, agera snabbt, samla bevis och dokumentera åtgärder. Det var inte bara tekniska steg, utan också beslut om vad som är säkrast för processen.

Den mest lärorika delen var Del 2 + Del 4 i kombination. Del 2 gav arkitekturen och kontrollerna som gjorde incidentrespons möjlig, medan Del 4 visade hur viktigt det är att ha både detektion och en plan för hur man agerar vid ett faktisk intrång.

Om jag imorgon fick i uppdrag att säkra en riktig vattenrenings-PLC, skulle jag göra följande tre saker först:

1. Implementera en säker bastion med MFA och IP-allowlist.
   - Det stoppar snabbt den vanligaste initiala vektorn: stulna SSH-uppgifter på en jump-server.
2. Införa strikta regler för Modbus-skrivningar på nätverksnivå.
   - Varje skrivoperation bör antingen blockeras eller kräva en separat godkännandeprocess. Detta är ett starkt skydd mot obehörig processmanipulering.
3. Lägga till process-side interlocks i PLC:n.
   - En skyddad intern gräns som vägrar farliga setpoint-värden är en viktig sista skyddsbarriär om nätverksskyddet sviker.

I den här labbarkitekturen är det svåraste att försvara mot just pivotering via bastionen. Jump-servern är en legitim åtkomstpunkt med både IT- och OT-närvaro, vilket gör den till en högvärdesmåltavla. Om angriparen tar över bastionen kan hen sedan röra sig fritt mot PLC och HMI, och det är svårt att skilja legitima från angripna kommandon om inte sessioner och källa IP hålls strikt under kontroll.

Slutligen visar labben att OT-säkerhet måste vara ett flerlager skydd: segmentering och detektion ger inblick, men processen måste också vara säkrad med både preventiva kontroller och en robust IR-plan. Utan en plan för "soft kill" och kontrollerad återställning är risken att man gör mer skada än nytta i en riktig incident.
