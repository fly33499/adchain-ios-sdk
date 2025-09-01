#!/bin/bash

# AdChainSDK Framework Build Script

FRAMEWORK_NAME="AdChainSDK"
BUILD_DIR="./build"
OUTPUT_DIR="./output"

echo "Building $FRAMEWORK_NAME.framework..."

# Clean previous builds
rm -rf $BUILD_DIR
rm -rf $OUTPUT_DIR

# Create output directory
mkdir -p $OUTPUT_DIR

# Build for iOS Simulator
echo "Building for iOS Simulator..."
cd AdChainSDK
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -archivePath "../$BUILD_DIR/simulator.xcarchive" \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
    ONLY_ACTIVE_ARCH=NO

# Build for iOS Device
echo "Building for iOS Device..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -archivePath "../$BUILD_DIR/device.xcarchive" \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=NO

cd ..

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework $BUILD_DIR/simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework \
    -framework $BUILD_DIR/device.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework \
    -output $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework

if [ -d "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework" ]; then
    echo "✅ Successfully built $FRAMEWORK_NAME.xcframework"
    echo "📍 Location: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
else
    echo "❌ Failed to build framework"
    exit 1
fi