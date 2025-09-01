#!/bin/bash

# Build static library for AdChainSDK

FRAMEWORK_NAME="AdChainSDK"
BUILD_DIR="./build"
OUTPUT_DIR="./output"

echo "🔨 Building $FRAMEWORK_NAME static library..."

# Clean
rm -rf $BUILD_DIR
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

cd AdChainSDK

# Build for simulator
echo "📱 Building for Simulator..."
xcodebuild build \
    -scheme $FRAMEWORK_NAME \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "../$BUILD_DIR/simulator" \
    -configuration Release \
    SKIP_INSTALL=NO

# Build for device  
echo "📱 Building for Device..."
xcodebuild build \
    -scheme $FRAMEWORK_NAME \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -derivedDataPath "../$BUILD_DIR/device" \
    -configuration Release \
    SKIP_INSTALL=NO

cd ..

# Find built products
SIM_LIB=$(find $BUILD_DIR/simulator -name "*.o" -type f | head -1)
DEV_LIB=$(find $BUILD_DIR/device -name "*.o" -type f | head -1)

if [ -f "$SIM_LIB" ] && [ -f "$DEV_LIB" ]; then
    echo "✅ Build succeeded"
    echo "Simulator lib: $SIM_LIB"
    echo "Device lib: $DEV_LIB"
    
    # Copy to output
    cp "$SIM_LIB" "$OUTPUT_DIR/AdChainSDK-sim.o"
    cp "$DEV_LIB" "$OUTPUT_DIR/AdChainSDK-device.o"
    
    echo "📦 Libraries copied to $OUTPUT_DIR"
else
    echo "❌ Build failed"
    exit 1
fi