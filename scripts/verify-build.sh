#!/bin/bash
# Verify both app targets build without warnings or errors.
# Run from project root: ./scripts/verify-build.sh
set -euo pipefail

PROJ="Slideshow.xcodeproj"
WARNINGS_AS_ERRORS="SWIFT_TREAT_WARNINGS_AS_ERRORS=YES"

echo "=== Generating Xcode project ==="
xcodegen generate

echo ""
echo "=== Running SlideshowKit tests ==="
cd SlideshowKit && swift test && cd ..

echo ""
echo "=== Building macOS target (warnings as errors) ==="
xcodebuild -project "$PROJ" \
  -scheme Slideshow \
  -destination 'platform=macOS' \
  "$WARNINGS_AS_ERRORS" \
  build 2>&1 | tail -5

echo ""
echo "=== Building iOS target (warnings as errors) ==="
xcodebuild -project "$PROJ" \
  -scheme SlideshowMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  "$WARNINGS_AS_ERRORS" \
  build 2>&1 | tail -5

echo ""
echo "=== All checks passed ==="
