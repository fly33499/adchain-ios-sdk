#!/bin/bash

# iOS SDK Test Runner Script

set -e

echo "================================"
echo "AdChain iOS SDK Test Runner"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to SDK directory
cd "$(dirname "$0")/AdChainSDK"

# Function to run tests
run_tests() {
    local test_filter=$1
    local test_name=$2
    
    echo -e "${YELLOW}Running ${test_name}...${NC}"
    
    if swift test --filter "$test_filter"; then
        echo -e "${GREEN}✅ ${test_name} passed${NC}"
        return 0
    else
        echo -e "${RED}❌ ${test_name} failed${NC}"
        return 1
    fi
}

# Check command line arguments
if [ "$1" == "mocked" ]; then
    echo "Running mocked tests only..."
    run_tests "MockedTests" "Mocked Tests"
elif [ "$1" == "integration" ]; then
    echo "Running integration tests only..."
    echo -e "${YELLOW}Make sure local server is running: npm run start:local${NC}"
    run_tests "LocalServerTests" "Integration Tests"
elif [ "$1" == "all" ] || [ -z "$1" ]; then
    echo "Running all tests..."
    
    # Run mocked tests first
    run_tests "MockedTests" "Mocked Tests"
    MOCKED_RESULT=$?
    
    # Run integration tests
    echo ""
    echo -e "${YELLOW}Make sure local server is running: npm run start:local${NC}"
    run_tests "LocalServerTests" "Integration Tests"
    INTEGRATION_RESULT=$?
    
    # Summary
    echo ""
    echo "================================"
    echo "Test Summary"
    echo "================================"
    
    if [ $MOCKED_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ Mocked Tests: PASSED${NC}"
    else
        echo -e "${RED}❌ Mocked Tests: FAILED${NC}"
    fi
    
    if [ $INTEGRATION_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ Integration Tests: PASSED${NC}"
    else
        echo -e "${RED}❌ Integration Tests: FAILED${NC}"
    fi
    
    if [ $MOCKED_RESULT -ne 0 ] || [ $INTEGRATION_RESULT -ne 0 ]; then
        exit 1
    fi
else
    echo "Usage: $0 [mocked|integration|all]"
    echo ""
    echo "  mocked      - Run only mocked tests"
    echo "  integration - Run only integration tests (requires local server)"
    echo "  all         - Run all tests (default)"
    echo ""
    exit 1
fi

echo ""
echo "✨ Tests completed!"