#!/bin/bash

# Script to test macOS DMG build workflow locally
# This simulates what GitHub Actions will run for the DMG build

set -e  # Exit on error

echo "🍎 Testing macOS DMG Build Workflow Locally"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to run a test step
test_step() {
    local step_name=$1
    local command=$2
    local optional=${3:-false}
    
    echo -e "${YELLOW}Testing: ${step_name}${NC}"
    if eval "$command"; then
        echo -e "${GREEN}✓ ${step_name} passed${NC}"
        ((PASSED++))
        echo ""
        return 0
    else
        if [ "$optional" = "true" ]; then
            echo -e "${BLUE}⚠ ${step_name} skipped (optional)${NC}"
            echo ""
            return 0
        else
            echo -e "${RED}✗ ${step_name} failed${NC}"
            ((FAILED++))
            echo ""
            return 1
        fi
    fi
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}✗ This script must be run on macOS${NC}"
    exit 1
fi

# Check if FVM is installed
if ! command -v fvm &> /dev/null; then
    echo -e "${YELLOW}⚠ FVM not found. Installing...${NC}"
    dart pub global activate fvm
    export PATH="$HOME/.pub-cache/bin:$PATH"
fi

# Setup Flutter via FVM (same logic as workflow)
echo -e "${BLUE}Setting up Flutter via FVM...${NC}"
if [ -f ".fvmrc" ]; then
    FLUTTER_VERSION=$(grep -o '"flutter":"[^"]*"' .fvmrc | cut -d'"' -f4)
    echo "Using Flutter version from .fvmrc: $FLUTTER_VERSION"
    fvm install $FLUTTER_VERSION
    fvm use $FLUTTER_VERSION --force
elif [ -f ".fvm/fvm_config.json" ]; then
    FLUTTER_VERSION=$(grep -o '"flutterSdkVersion":"[^"]*"' .fvm/fvm_config.json | cut -d'"' -f4)
    echo "Using Flutter version from FVM config: $FLUTTER_VERSION"
    fvm install $FLUTTER_VERSION
    fvm use $FLUTTER_VERSION --force
else
    FLUTTER_VERSION="3.29.3"
    echo "FVM config not found, using Flutter version: $FLUTTER_VERSION"
    fvm install $FLUTTER_VERSION
    fvm use $FLUTTER_VERSION --force
fi
fvm flutter --version
echo ""

# Test 1: Get dependencies
test_step "Get Dependencies" "fvm flutter pub get"

# Test 2: Formatting
test_step "Code Formatting" "fvm dart format --set-exit-if-changed ."

# Test 3: Code Analysis
test_step "Code Analysis" "fvm flutter analyze"

# Test 4: Run tests
test_step "Run Tests" "fvm flutter test"

# Test 5: Build macOS App (Release)
test_step "Build macOS App (Release)" "fvm flutter build macos --release"

# Test 6: Create DMG
echo -e "${YELLOW}Testing: Create DMG${NC}"
if [ -f "macos/Runner/Configs/AppInfo.xcconfig" ]; then
    APP_NAME=$(grep "PRODUCT_NAME" macos/Runner/Configs/AppInfo.xcconfig | cut -d'=' -f2 | xargs)
else
    APP_NAME="lingo_desk"
fi

APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}✗ App not found at: $APP_PATH${NC}"
    ((FAILED++))
else
    echo -e "${GREEN}✓ App found at: $APP_PATH${NC}"
    
    # Generate DMG name
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")
    GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    DMG_NAME="${APP_NAME}-${GIT_BRANCH}-${GIT_SHA}.dmg"
    DMG_PATH="build/${DMG_NAME}"
    
    # Create a temporary directory for DMG contents
    DMG_TEMP_DIR=$(mktemp -d)
    echo "Using temporary directory: $DMG_TEMP_DIR"
    
    # Copy the app to the temporary directory
    cp -R "${APP_PATH}" "${DMG_TEMP_DIR}/"
    
    # Create a symbolic link to Applications folder
    ln -s /Applications "${DMG_TEMP_DIR}/Applications"
    
    # Create the DMG
    VOLUME_NAME=$(echo "${APP_NAME}" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
    echo "Creating DMG with volume name: ${VOLUME_NAME}"
    
    if hdiutil create -volname "${VOLUME_NAME}" \
        -srcfolder "${DMG_TEMP_DIR}" \
        -ov -format UDZO \
        "${DMG_PATH}"; then
        echo -e "${GREEN}✓ DMG created successfully${NC}"
        echo "DMG location: ${DMG_PATH}"
        ls -lh "${DMG_PATH}"
        ((PASSED++))
    else
        echo -e "${RED}✗ DMG creation failed${NC}"
        ((FAILED++))
    fi
    
    # Clean up temporary directory
    rm -rf "${DMG_TEMP_DIR}"
fi
echo ""

# Summary
echo "==========================================="
echo -e "${GREEN}Passed: ${PASSED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: ${FAILED}${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed! ✓${NC}"
    if [ -f "$DMG_PATH" ]; then
        echo ""
        echo -e "${BLUE}📦 DMG file created: ${DMG_PATH}${NC}"
        echo -e "${BLUE}   You can test it by double-clicking or running:${NC}"
        echo -e "${BLUE}   open ${DMG_PATH}${NC}"
    fi
    exit 0
fi

