#!/bin/bash

# iOS SDK Build Script

set -e

FRAMEWORK_NAME="AdChainSDK"
BUILD_DIR="./build"
OUTPUT_DIR="./output"
PROJECT_DIR="./AdChainSDK"

echo "🔨 Building $FRAMEWORK_NAME..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf $BUILD_DIR
rm -rf $OUTPUT_DIR

# Create directories
mkdir -p $BUILD_DIR
mkdir -p $OUTPUT_DIR

cd $PROJECT_DIR

# Build for iOS Simulator (arm64)
echo "📱 Building for iOS Simulator (arm64)..."
xcodebuild build \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "../$BUILD_DIR/simulator" \
    -configuration Release \
    SKIP_INSTALL=NO \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="arm64" \
    VALID_ARCHS="arm64"

# Build for iOS Device
echo "📱 Building for iOS Device..."
xcodebuild build \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS" \
    -derivedDataPath "../$BUILD_DIR/device" \
    -configuration Release \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

cd ..

# Find the framework paths
SIMULATOR_FRAMEWORK=$(find $BUILD_DIR/simulator -name "$FRAMEWORK_NAME.framework" -type d | head -n 1)
DEVICE_FRAMEWORK=$(find $BUILD_DIR/device -name "$FRAMEWORK_NAME.framework" -type d | head -n 1)

if [ -z "$SIMULATOR_FRAMEWORK" ] || [ -z "$DEVICE_FRAMEWORK" ]; then
    echo "❌ Failed to find built frameworks"
    exit 1
fi

echo "✅ Found frameworks:"
echo "  Simulator: $SIMULATOR_FRAMEWORK"
echo "  Device: $DEVICE_FRAMEWORK"

# Create XCFramework
echo "🔧 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$SIMULATOR_FRAMEWORK" \
    -framework "$DEVICE_FRAMEWORK" \
    -output "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

if [ -d "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework" ]; then
    echo "✅ Successfully built $FRAMEWORK_NAME.xcframework"
    echo "📍 Location: $(pwd)/$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
    ls -la "$OUTPUT_DIR"
else
    echo "❌ Failed to build XCFramework"
    exit 1
fi