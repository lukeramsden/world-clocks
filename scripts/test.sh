#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
sources=()
for source in Sources/WorldClocks/*.swift; do
    if [[ "$source" != */main.swift ]]; then sources+=("$source"); fi
done
xcrun swiftc -target "$(uname -m)-apple-macosx14.0" \
    "${sources[@]}" Tests/main.swift \
    -framework AppKit -framework SwiftUI -framework QuartzCore \
    -o .build/WorldClocksTests
.build/WorldClocksTests
