#!/bin/bash
set -e

# ─────────────────────────────────────────────
# Sticky Fingers — Release Script
# Usage: ./release.sh 1.0.1
#
# Builds a Release .app and zips it for manual
# distribution via GitHub Releases. (Sparkle
# auto-update was removed — users download and
# replace the app themselves.)
# ─────────────────────────────────────────────

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Error: provide a version number."
    echo "Usage: ./release.sh 1.0.1"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/Sticky Fingers.xcodeproj"
PLIST="$SCRIPT_DIR/Sticky Fingers/Info.plist"
BUILD_DIR="$SCRIPT_DIR/build-release"
ZIP_NAME="StickyFingers.zip"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Releasing Sticky Fingers v$VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Bump version in Info.plist
echo "Step 1: Bumping version to $VERSION..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
# Increment CFBundleVersion as an integer build number (YYYYMMDDHHMM-based)
BUILD_NUMBER=$(date +%Y%m%d%H%M)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST"
echo "  CFBundleShortVersionString = $VERSION"
echo "  CFBundleVersion = $BUILD_NUMBER"

# Step 2: Build Release .app
echo ""
echo "Step 2: Building Release app..."
rm -rf "$BUILD_DIR"
xcodebuild \
    -project "$PROJECT" \
    -scheme "Sticky Fingers" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    DEPLOYMENT_LOCATION=NO \
    BUILD_DIR="$BUILD_DIR" \
    build
APP_PATH="$BUILD_DIR/Release/Sticky Fingers.app"
echo "  Built: $APP_PATH"

# Step 3: Zip the .app
echo ""
echo "Step 3: Zipping app..."
cd "$BUILD_DIR/Release"
ditto -c -k --keepParent "Sticky Fingers.app" "$ZIP_NAME"
ZIP_PATH="$BUILD_DIR/Release/$ZIP_NAME"
FILE_SIZE=$(stat -f%z "$ZIP_PATH")
echo "  Created: $ZIP_PATH ($FILE_SIZE bytes)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DONE"
echo ""
echo "  Version:   $VERSION"
echo "  Build:     $BUILD_NUMBER"
echo "  File size: $FILE_SIZE"
echo ""
echo "  Zip file is at:"
echo "  $ZIP_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "  1. Create a new GitHub Release tagged v$VERSION"
echo "  2. Upload $ZIP_NAME as a release asset"
echo "  3. Write release notes describing what changed"
echo "  4. Users download the new version and replace the app manually"
echo ""
