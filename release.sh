#!/bin/bash
set -e

# ─────────────────────────────────────────────
# Sticky Fingers — Release Script
# Usage: ./release.sh 1.0.1
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
SIGN_UPDATE="$SCRIPT_DIR/Frameworks/sparkle-bin/sign_update"
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
# Increment CFBundleVersion as an integer build number (YYYYMMDD-based)
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

# Step 4: Sign the zip with Sparkle
echo ""
echo "Step 4: Signing zip with EdDSA key..."
chmod +x "$SIGN_UPDATE"
SIGNATURE=$("$SIGN_UPDATE" "$ZIP_PATH" 2>/dev/null | grep -o 'sparkle:edDSASignature="[^"]*"' | sed 's/sparkle:edDSASignature="//;s/"//')
if [ -z "$SIGNATURE" ]; then
    # Try alternate output format
    SIGNATURE=$("$SIGN_UPDATE" "$ZIP_PATH" 2>&1)
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DONE — copy these values into appcast.xml:"
echo ""
echo "  Version:   $VERSION"
echo "  Build:     $BUILD_NUMBER"
echo "  File size: $FILE_SIZE"
echo "  Signature: $SIGNATURE"
echo ""
echo "  Zip file is at:"
echo "  $ZIP_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "  1. Upload $ZIP_NAME to GitHub Releases as v$VERSION"
echo "  2. Copy the signature above into appcast.xml"
echo "  3. Update the version and URL in appcast.xml"
echo "  4. Push appcast.xml to GitHub"
echo ""
