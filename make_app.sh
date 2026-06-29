#!/bin/bash
set -e
trap 'rm -f /tmp/qrski_partial.plist' EXIT

VERSION=$(grep -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '[]')
if [ -z "$VERSION" ]; then
  echo "error: could not detect version from CHANGELOG.md"
  exit 1
fi
echo "→ Version: ${VERSION}"

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

cat > QRski.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>QRski</string>
  <key>CFBundleIdentifier</key><string>com.creativytool.qrski</string>
  <key>CFBundleName</key><string>QRski</string>
  <key>CFBundleDisplayName</key><string>QRski</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>CFBundleIconName</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
EOF

if [ -f /tmp/qrski_partial.plist ]; then
  /usr/libexec/PlistBuddy -c "Merge /tmp/qrski_partial.plist" QRski.app/Contents/Info.plist 2>/dev/null || true
fi

echo "→ Ad-hoc signing..."
codesign --sign - --force QRski.app

echo "✓ QRski.app is ready"
echo "  To share: zip -r QRski.zip QRski.app"
