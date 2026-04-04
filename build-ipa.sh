#!/bin/bash
set -e

echo "📦 Building Gemma4iOS IPA..."

# Clean
xcodebuild clean -project Gemma4iOS.xcodeproj -scheme Gemma4iOS

# Build for device
xcodebuild archive \
  -project Gemma4iOS.xcodeproj \
  -scheme Gemma4iOS \
  -sdk iphoneos \
  -configuration Release \
  -archivePath build/Gemma4iOS.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Create Payload
mkdir -p build/Payload
cp -r build/Gemma4iOS.xcarchive/Products/Applications/Gemma4iOS.app build/Payload/

# Create IPA
cd build
zip -r Gemma4iOS.ipa Payload
cd ..

mv build/Gemma4iOS.ipa ./Gemma4iOS.ipa

echo "✅ IPA created: Gemma4iOS.ipa"
