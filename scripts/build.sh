#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app='.build/World Clocks.app'
mkdir -p "$app/Contents/MacOS"
xcrun swiftc -O -target "$(uname -m)-apple-macosx14.0" \
    Sources/WorldClocks/*.swift \
    -framework AppKit -framework SwiftUI -framework QuartzCore \
    -o "$app/Contents/MacOS/WorldClocks"
cp Info.plist "$app/Contents/Info.plist"
xattr -cr "$app"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
echo "Built $app"
