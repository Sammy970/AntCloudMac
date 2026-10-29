#!/usr/bin/env bash
# Builds AntCloud.app from the Swift package. Usage: scripts/build-app.sh [--bundle-moonlight]
set -euo pipefail

cd "$(dirname "$0")/.."
swift build -c release

APP=build/AntCloud.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/AntCloud" "$APP/Contents/MacOS/AntCloud"
cp AntCloud.icns "$APP/Contents/Resources/AntCloud.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>AntCloud</string>
    <key>CFBundleDisplayName</key><string>AntCloud</string>
    <key>CFBundleIdentifier</key><string>co.antcloud.mac</string>
    <key>CFBundleExecutable</key><string>AntCloud</string>
    <key>CFBundleIconFile</key><string>AntCloud</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSMicrophoneUsageDescription</key><string>AntCloud forwards your microphone to your cloud PC.</string>
</dict>
</plist>
PLIST

# Optionally ship Moonlight inside the bundle so users don't need a separate install.
if [[ "${1:-}" == "--bundle-moonlight" ]]; then
  cp -R /Applications/Moonlight.app "$APP/Contents/Resources/Moonlight.app"
fi

codesign --force --deep --sign - "$APP"
echo "Built $APP"
