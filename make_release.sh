#!/bin/bash
set -e

# Usage: bash make_release.sh [version]
# If version is omitted, reads it from the latest [x.y.z] entry in CHANGELOG.md

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  VERSION=$(grep -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '[]')
  if [ -z "$VERSION" ]; then
    echo "error: could not detect version from CHANGELOG.md — pass it explicitly: bash make_release.sh 1.0.0"
    exit 1
  fi
fi

TAG="v${VERSION}"
ZIPFILE="QRski-${TAG}.zip"

echo "→ Version: ${VERSION} (tag: ${TAG})"

# Build app bundle
bash make_app.sh

echo "→ Zipping QRski.app → ${ZIPFILE}..."
rm -f "${ZIPFILE}"
zip -r --symlinks "${ZIPFILE}" QRski.app

echo ""
echo "✓ ${ZIPFILE} is ready ($(du -sh "${ZIPFILE}" | cut -f1))"
echo ""
echo "Next steps:"
echo ""
echo "  1. Commit & push any pending changes, then run:"
echo ""
echo "     gh release create ${TAG} ${ZIPFILE} \\"
echo "       --title \"QRski ${VERSION}\" \\"
echo "       --notes-file <(awk '/^## \[${VERSION}\]/{found=1; next} found && /^## \[/{exit} found{print}' CHANGELOG.md)"
echo ""
echo "  Users on macOS will need to right-click → Open the first time (Gatekeeper, unsigned app)."
