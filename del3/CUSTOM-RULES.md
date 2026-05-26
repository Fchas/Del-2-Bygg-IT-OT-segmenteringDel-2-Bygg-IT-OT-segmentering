# Suricata Rules for OT Modbus Monitoring
# Lab 2 Del 3 - Custom Rules

## CUSTOM RULE A: FC8 Diagnostics (DoS Detection)
## 
## Function 8 (Diagnostics) with subfunction 4 (Force Listen Only Mode)
## stops the PLC from responding to commands — a classic OT DoS.
## Alert on any FC8 as a potential DoS attempt.

alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-DIAG: Modbus Diagnostics (FC8) — potential DoS"; \
    flow:to_server,established; \
    modbus: function 8; \
    classtype:attempted-dos; \
    sid:1000100; rev:1; priority:1; \
)

## CUSTOM RULE B: Unsafe Setpoint Value (Safety Range)
##
## Process constraint: Setpoint must be between 1000-8000.
## Values > 8000 risk overpressure/equipment damage.
## Alert when FC6 (Write Single Register) sets value outside safe range.

alert modbus any any -> $OT_NET 502 ( \
    msg:"OT-WRITE-CRITICAL: Setpoint > 8000 (unsafe range)"; \
    flow:to_server,established; \
    modbus: function 6, address 0, value >8000; \
    classtype:attempted-admin; \
    sid:1000101; rev:1; priority:1; \
)

## CUSTOM RULE C: OT Recon Scan Detection
##
## Detect repeated TCP SYNs to the OT zone as reconnaissance activity.
alert tcp any any -> $OT_NET any ( \
    msg:"OT-RECON: TCP scan against OT zone"; \
    flow:to_server; \
    flags:S; \
    threshold: type both, track by_src, count 5, seconds 5; \
    classtype:attempted-recon; \
    sid:1000200; rev:1; \
)

## NOTES:
## - SID 1000000+ reserved for custom rules
## - SID 2000000+ reserved for base rules
## - Priority 1 = highest severity
## - classtype affects default alert priority in Suricata
## - flow:to_server,established prevents false positives on response packets
