#!/bin/bash

# Lab 2 Del 2 - Segmentation Verification Script
# Tests 6 critical network flows to verify Purdue-model segmentation

set -e

PASS=0
FAIL=0

test_flow() {
    local from_container=$1
    local to_host=$2
    local to_port=$3
    local expected=$4
    local description=$5

    # Use nc (netcat) to test connectivity with timeout
    result=$(docker exec "$from_container" nc -z -v -w 2 "$to_host" "$to_port" 2>&1 || true)
    
    if echo "$result" | grep -q "succeeded\|open"; then
        actual="ALLOW"
    else
        actual="BLOCK"
    fi

    if [ "$actual" = "$expected" ]; then
        echo "  ✓ OK     $description (expected $expected, got $actual)"
        ((PASS++))
    else
        echo "  ✗ BROKEN $description (expected $expected, got $actual)"
        ((FAIL++))
    fi
}

echo ""
echo " Illegitima vägar — får INTE gå igenom:"
test_flow "lab2-attacker" "mock-plc" "502" "BLOCK" "attacker (IT) → mock-plc:502 (OT)"
test_flow "lab2-plc" "1.1.1.1" "53" "BLOCK" "mock-plc (OT) → internet (1.1.1.1:53)"

echo ""
echo " Legitima vägar — SKA fungera:"
test_flow "lab2-attacker" "jump-server" "22" "ALLOW" "attacker (IT) → jump-server:22 (DMZ)"
test_flow "lab2-jump" "mock-plc" "502" "ALLOW" "jump-server (DMZ) → mock-plc:502 (OT)"
test_flow "lab2-historian" "mock-plc" "502" "ALLOW" "historian (DMZ) → mock-plc:502 (OT)"
test_flow "lab2-historian" "1.1.1.1" "53" "ALLOW" "historian (DMZ) → internet (1.1.1.1:53)"

echo ""
if [ $FAIL -eq 0 ]; then
    echo " Alla 6 kontroller OK — segmenteringen är korrekt."
    exit 0
else
    echo " $FAIL av 6 kontroller misslyckades."
    exit 1
fi
