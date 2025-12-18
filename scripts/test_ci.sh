#!/bin/bash

# Script to test CI workflow steps locally
# This simulates what GitHub Actions will run

set -e  # Exit on error

echo "🧪 Testing CI Workflow Steps Locally"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to run a test step
test_step() {
    local step_name=$1
    local command=$2
    
    echo -e "${YELLOW}Testing: ${step_name}${NC}"
    if eval "$command"; then
        echo -e "${GREEN}✓ ${step_name} passed${NC}"
        ((PASSED++))
        echo ""
        return 0
    else
        echo -e "${RED}✗ ${step_name} failed${NC}"
        ((FAILED++))
        echo ""
        return 1
    fi
}

# Test 1: Formatting
test_step "Code Formatting" "fvm dart format --set-exit-if-changed ."

# Test 2: Code Analysis
test_step "Code Analysis" "fvm flutter analyze --no-fatal-infos"

# Test 3: Unit Tests
test_step "Unit Tests" "fvm flutter test test/unit"

# Test 4: Widget Tests
test_step "Widget Tests" "fvm flutter test test/widget"

# Test 5: All Tests with Coverage
test_step "All Tests with Coverage" "fvm flutter test --coverage"

# Test 6: Verify coverage file exists
if [ -f "coverage/lcov.info" ]; then
    echo -e "${GREEN}✓ Coverage file generated${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Coverage file not found${NC}"
    ((FAILED++))
fi
echo ""

# Summary
echo "===================================="
echo -e "${GREEN}Passed: ${PASSED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: ${FAILED}${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
fi

