#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# BSD mktemp only substitutes trailing X's, so make a temp dir and place the .plist inside it.
PARTIAL_DIR=$(mktemp -d /tmp/qrski_partial.XXXXXX)
PARTIAL_PLIST="$PARTIAL_DIR/partial.plist"
trap 'rm -rf "$PARTIAL_DIR"' EXIT

# Version comes from make_release.sh as $1; standalone runs derive it from the
# latest release heading in CHANGELOG.md.
VERSION="${1:-$(grep -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '[]' || true)}"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: invalid or missing version '${VERSION}' — pass x.y.z as \$1 or release it in CHANGELOG.md"
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
  --output-partial-info-plist "$PARTIAL_PLIST" \
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

if [ -f "$PARTIAL_PLIST" ]; then
  if ! /usr/libexec/PlistBuddy -c "Merge $PARTIAL_PLIST" QRski.app/Contents/Info.plist; then
    echo "warning: could not merge asset catalog partial plist — app icon keys may be missing from Info.plist"
  fi
fi

echo "→ Bundling license files..."
cp LICENSE QRski.app/Contents/Resources/LICENSE
cp LICENSE.libqrencode QRski.app/Contents/Resources/LICENSE.libqrencode

echo "→ Ad-hoc signing..."
codesign --sign - --force QRski.app

echo "✓ QRski.app is ready"
echo "  To share: zip -r QRski.zip QRski.app"
