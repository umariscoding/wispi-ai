#!/bin/bash
cd "$(dirname "$0")"

# Load configuration
source ./config.sh

APP_DIR="$APP_NAME.app"

echo "Building $APP_NAME..."

# Update display name in Swift code
sed -i '' "s/let APP_NAME = \".*\"/let APP_NAME = \"$DISPLAY_NAME\"/" Sources/Config/AppConfig.swift

# Collect all Swift source files
SWIFT_FILES=$(find Sources -name "*.swift" -type f)

swiftc $SWIFT_FILES -o "$APP_NAME" -framework Cocoa -framework Foundation -framework ScreenCaptureKit -framework AVFoundation -framework CoreMedia -O -whole-module-optimization 2>&1

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Remove old app bundles
rm -rf *.app 2>/dev/null

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mv "$APP_NAME" "$APP_DIR/Contents/MacOS/"

cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Screen analysis</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Audio recording for meeting transcription</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_DIR" 2>/dev/null

echo ""
echo "✓ Built: $APP_DIR"
echo "  Run: open $APP_DIR"
