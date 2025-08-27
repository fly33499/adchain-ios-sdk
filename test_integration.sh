#!/bin/bash

# iOS SDK Integration Test Runner
# This script runs integration tests against a local server

set -e

echo "======================================"
echo "AdChain iOS SDK Integration Test"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_DIR="../../adchain-server"
SDK_DIR="$(dirname "$0")/AdChainSDK"
SERVER_URL="http://localhost:3000"

# Function to check if server is running
check_server() {
    if curl -s -o /dev/null -w "%{http_code}" "$SERVER_URL/health" | grep -q "200"; then
        return 0
    else
        return 1
    fi
}

# Function to start server
start_server() {
    echo -e "${YELLOW}Starting local server...${NC}"
    
    cd "$SERVER_DIR"
    
    # Check if npm dependencies are installed
    if [ ! -d "node_modules" ]; then
        echo "Installing server dependencies..."
        npm install
    fi
    
    # Start server in background
    npm run start:local > /tmp/adchain-server.log 2>&1 &
    SERVER_PID=$!
    
    echo "Server starting (PID: $SERVER_PID)..."
    
    # Wait for server to be ready
    for i in {1..30}; do
        if check_server; then
            echo -e "${GREEN}✅ Server is ready!${NC}"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    echo ""
    echo -e "${RED}❌ Server failed to start${NC}"
    echo "Check server logs at /tmp/adchain-server.log"
    return 1
}

# Function to stop server
stop_server() {
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${YELLOW}Stopping server (PID: $SERVER_PID)...${NC}"
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
}

# Function to reset test data
reset_test_data() {
    echo -e "${BLUE}Resetting test data...${NC}"
    curl -s -X POST "$SERVER_URL/v1/test/reset" > /dev/null
    curl -s -X POST "$SERVER_URL/v1/test/seed" > /dev/null
    echo -e "${GREEN}✅ Test data ready${NC}"
}

# Trap to ensure cleanup on exit
trap stop_server EXIT

# Main execution
echo "Checking local server..."

if check_server; then
    echo -e "${GREEN}✅ Server is already running${NC}"
    SERVER_STARTED_HERE=false
else
    echo -e "${YELLOW}⚠️  Server is not running${NC}"
    
    # Ask user if they want to start the server
    read -p "Do you want to start the server automatically? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if start_server; then
            SERVER_STARTED_HERE=true
        else
            echo -e "${RED}Failed to start server. Exiting.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Server is required for integration tests. Exiting.${NC}"
        echo "Start the server manually with: cd $SERVER_DIR && npm run start:local"
        exit 1
    fi
fi

# Reset test data
echo ""
reset_test_data

# Run integration tests
echo ""
echo -e "${YELLOW}Running integration tests...${NC}"
echo ""

cd "$SDK_DIR"

if swift test --filter "LocalServerTests"; then
    echo ""
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
    TEST_RESULT=0
else
    echo ""
    echo -e "${RED}❌ Some integration tests failed${NC}"
    TEST_RESULT=1
fi

# Stop server if we started it
if [ "$SERVER_STARTED_HERE" == "true" ]; then
    echo ""
    stop_server
fi

echo ""
echo "======================================"
echo "Integration Test Complete"
echo "======================================"

exit $TEST_RESULT