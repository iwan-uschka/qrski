#!/bin/bash
set -euo pipefail
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

# make_app.sh re-derives the version from CHANGELOG.md with a strict x.y.z grep;
# a malformed version here (e.g. "1.3") would stamp the changelog but ship the
# app with the *previous* version in Info.plist.
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be x.y.z (got '${VERSION}')"
  exit 1
fi

# The zip must be built from exactly the tree the release commit will contain.
if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is not clean — commit or stash changes before releasing"
  exit 1
fi

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  echo "error: tag ${TAG} already exists"
  exit 1
fi

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

# Build app bundle — pass the version explicitly so it can't drift from the tag
bash make_app.sh "${VERSION}"

if [ ! -d QRski.app ]; then
  echo "error: QRski.app not found — did make_app.sh fail?"
  exit 1
fi

echo "→ Zipping QRski.app → ${ZIPFILE}..."
rm -f "${ZIPFILE}" "${ZIPFILE}.sha256"
zip -r --symlinks "${ZIPFILE}" QRski.app

# The app is unsigned and un-notarized, so a published checksum is the only
# integrity signal users have for the download.
shasum -a 256 "${ZIPFILE}" > "${ZIPFILE}.sha256"

echo ""
echo "✓ ${ZIPFILE} is ready ($(du -sh "${ZIPFILE}" | cut -f1))"
echo "  SHA-256: $(cut -d' ' -f1 "${ZIPFILE}.sha256")"
echo ""
echo "Next steps:"
echo ""
echo "  1. Commit and push the changelog update:"
echo ""
echo "     git add CHANGELOG.md && git commit -m 'Release ${VERSION}' && git push"
echo ""
echo "  2. Create the GitHub release:"
echo ""
echo "     gh release create ${TAG} ${ZIPFILE} ${ZIPFILE}.sha256 \\"
echo "       --title \"QRski ${VERSION}\" \\"
echo "       --notes-file <(awk \"/^\#\# \[${VERSION}\]/{found=1; next} found && /^\#\# \[/{exit} found{print}\" CHANGELOG.md)"
echo ""
echo "  Note for users: the app is unsigned — on macOS 15+ they must allow it under"
echo "  System Settings → Privacy & Security after the first blocked launch attempt."
