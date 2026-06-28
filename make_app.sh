#!/bin/bash
set -e

echo "→ Building release binary..."
swift build -c release

echo "→ Assembling QRski.app..."
rm -rf QRski.app
mkdir -p QRski.app/Contents/MacOS
mkdir -p QRski.app/Contents/Resources

cp .build/release/QRski QRski.app/Contents/MacOS/QRski

echo "→ Compiling asset catalog..."
xcrun actool \
  --output-format human-readable-text \
  --notices --warnings \
  --output-partial-info-plist /tmp/qrski_partial.plist \
  --app-icon AppIcon \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --target-device mac \
  --minimum-deployment-target 14.0 \
  --platform macosx \
  --compile QRski.app/Contents/Resources \
  Sources/QRski/Assets.xcassets

cat > QRski.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>QRski</string>
  <key>CFBundleIdentifier</key><string>de.bitgrip.qrski</string>
  <key>CFBundleName</key><string>QRski</string>
  <key>CFBundleDisplayName</key><string>QRski</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconName</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
EOF

echo "→ Ad-hoc signing..."
codesign --sign - --force --deep QRski.app

echo "✓ QRski.app is ready"
echo "  To share: zip -r QRski.zip QRski.app"
