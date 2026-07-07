#!/bin/bash
set -e
cd "$(dirname "$0")"

# Usage: bash make_release.sh <version>
# Example: bash make_release.sh 1.2.0
#
# Renames [Unreleased] in CHANGELOG.md to [version] - today, builds the app,
# zips it, and prints the gh release create command to run.

if [ -z "${1:-}" ]; then
  echo "error: version required — usage: bash make_release.sh 1.2.0"
  exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
ZIPFILE="QRski-${TAG}.zip"
TODAY=$(date +%Y-%m-%d)

echo "→ Version: ${VERSION} (tag: ${TAG})"

# Verify [Unreleased] section has content
UNRELEASED=$(awk '/^\#\# \[Unreleased\]/{found=1; next} found && /^\#\# \[/{exit} found && NF{print}' CHANGELOG.md)
if [ -z "$UNRELEASED" ]; then
  echo "error: [Unreleased] section in CHANGELOG.md is empty — add entries before releasing"
  exit 1
fi

# Keep a pre-stamp backup so a failed build below doesn't leave CHANGELOG.md already stamped.
cp CHANGELOG.md CHANGELOG.md.bak
trap 'if [ $? -ne 0 ] && [ -f CHANGELOG.md.bak ]; then mv CHANGELOG.md.bak CHANGELOG.md; echo "→ CHANGELOG.md restored"; else rm -f CHANGELOG.md.bak; fi' EXIT

# Stamp [Unreleased] → [VERSION] - DATE and prepend a fresh [Unreleased]
awk -v ver="${VERSION}" -v date="${TODAY}" '
  !done && /^## \[Unreleased\]/ {
    print "## [Unreleased]"
    print ""
    print "## [" ver "] - " date
    done=1
    next
  }
  { print }
' CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md

echo "→ CHANGELOG.md updated"

# Build app bundle
bash make_app.sh

if [ ! -d QRski.app ]; then
  echo "error: QRski.app not found — did make_app.sh fail?"
  exit 1
fi

echo "→ Zipping QRski.app → ${ZIPFILE}..."
rm -f "${ZIPFILE}"
zip -r --symlinks "${ZIPFILE}" QRski.app

echo ""
echo "✓ ${ZIPFILE} is ready ($(du -sh "${ZIPFILE}" | cut -f1))"
echo ""
echo "Next steps:"
echo ""
echo "  1. Commit and push the changelog update:"
echo ""
echo "     git add CHANGELOG.md && git commit -m 'Release ${VERSION}' && git push"
echo ""
echo "  2. Create the GitHub release:"
echo ""
echo "     gh release create ${TAG} ${ZIPFILE} \\"
echo "       --title \"QRski ${VERSION}\" \\"
echo "       --notes-file <(awk \"/^\#\# \[${VERSION}\]/{found=1; next} found && /^\#\# \[/{exit} found{print}\" CHANGELOG.md)"
echo ""
echo "  Users on macOS will need to right-click → Open the first time (Gatekeeper, unsigned app)."
