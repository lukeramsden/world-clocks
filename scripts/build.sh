#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app='.build/World Clocks.app'
mkdir -p "$app/Contents/MacOS" .build/bin
read -r -a architectures <<< "${ARCHS:-$(uname -m)}"
binaries=()
for architecture in "${architectures[@]}"; do
    case "$architecture" in arm64|x86_64) ;; *) echo "Unsupported architecture: $architecture" >&2; exit 1 ;; esac
    binary=".build/bin/WorldClocks-$architecture"
    xcrun swiftc -O -target "$architecture-apple-macosx14.0" \
        Sources/WorldClocks/*.swift \
        -framework AppKit -framework SwiftUI -framework QuartzCore -o "$binary"
    binaries+=("$binary")
done
xcrun lipo -create "${binaries[@]}" -output "$app/Contents/MacOS/WorldClocks"
cp Info.plist "$app/Contents/Info.plist"
xattr -cr "$app"
identity="${SIGNING_IDENTITY:--}"
if [[ "$identity" == '-' ]]; then
    codesign --force --sign - "$app"
else
    codesign --force --options runtime --timestamp --sign "$identity" "$app"
fi
codesign --verify --strict "$app"
echo "Built $app ($(xcrun lipo -archs "$app/Contents/MacOS/WorldClocks"))"
