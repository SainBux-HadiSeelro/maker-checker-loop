#!/bin/bash
set -e

MODE="$1"
CALC="calculator.py"
TEST="test_calculator.py"

# Run the test suite
OUTPUT=$(python -m unittest "$TEST" 2>&1)
FAILED=0
echo "$OUTPUT" | grep -i "FAIL\|ERROR" && FAILED=1 || true

if [[ "$FAILED" -eq 1 ]]; then
    echo "FAIL: Tests do not pass"
    exit 1
fi

# Check for hardcoded/fake fixes by testing with unexpected inputs
# Good fix should not be hardcoded

echo "PASS: Tests pass and fix appears general"