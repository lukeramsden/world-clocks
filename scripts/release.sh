#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
if [[ -n "${RELEASE_TAG:-}" && "$RELEASE_TAG" != "v$version" ]]; then
    echo "Release tag $RELEASE_TAG does not match Info.plist version $version" >&2
    exit 1
fi
./scripts/test.sh
ARCHS='arm64 x86_64' ./scripts/build.sh
app='.build/World Clocks.app'
staging=$(mktemp -d "${TMPDIR:-/tmp}/world-clocks-release.XXXXXX")
trap 'rm -rf "$staging"' EXIT
mkdir -p dist
dmg="dist/World-Clocks-$version-universal.dmg"
zip="dist/World-Clocks-$version-universal.zip"
ditto "$app" "$staging/World Clocks.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname 'World Clocks' -srcfolder "$staging" -ov -format UDZO "$dmg"
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    if [[ "${SIGNING_IDENTITY:--}" == '-' ]]; then
        echo 'Notarization requires a Developer ID signing identity' >&2
        exit 1
    fi
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$dmg"
    xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$dmg"
    xcrun stapler staple "$app"
fi
ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"
(cd dist && shasum -a 256 "World-Clocks-$version-universal.dmg" "World-Clocks-$version-universal.zip" > SHA256SUMS.txt)
echo "Release packages are in dist/"
