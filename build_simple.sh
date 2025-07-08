#!/bin/bash

# Simple iOS SDK Build Script - Simulator only

set -e

FRAMEWORK_NAME="AdChainSDK"
BUILD_DIR="./build"
OUTPUT_DIR="./output"
PROJECT_DIR="./AdChainSDK"

echo "🔨 Building $FRAMEWORK_NAME for Simulator..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf $BUILD_DIR
rm -rf $OUTPUT_DIR

# Create directories
mkdir -p $BUILD_DIR
mkdir -p $OUTPUT_DIR

cd $PROJECT_DIR

# Build for iOS Simulator only
echo "📱 Building for iOS Simulator..."
xcodebuild build \
    -scheme $FRAMEWORK_NAME \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,id=143C3DED-14E2-4D18-A3BB-4C7C6312F026' \
    -derivedDataPath "../$BUILD_DIR/simulator" \
    -configuration Release \
    SKIP_INSTALL=NO

cd ..

# Find the framework path
FRAMEWORK_PATH=$(find $BUILD_DIR/simulator -name "$FRAMEWORK_NAME.framework" -type d | head -n 1)

if [ -z "$FRAMEWORK_PATH" ]; then
    echo "❌ Failed to find built framework"
    exit 1
fi

echo "✅ Found framework: $FRAMEWORK_PATH"

# Copy framework to output
cp -R "$FRAMEWORK_PATH" "$OUTPUT_DIR/"

if [ -d "$OUTPUT_DIR/$FRAMEWORK_NAME.framework" ]; then
    echo "✅ Successfully built $FRAMEWORK_NAME.framework"
    echo "📍 Location: $(pwd)/$OUTPUT_DIR/$FRAMEWORK_NAME.framework"
    ls -la "$OUTPUT_DIR"
else
    echo "❌ Failed to copy framework"
    exit 1
fi