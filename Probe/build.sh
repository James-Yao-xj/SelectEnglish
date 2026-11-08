#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
unsigned=false
skip_tests=false
for option in "$@"; do
    case "$option" in
        --unsigned) unsigned=true ;;
        --skip-tests) skip_tests=true ;;
        *) echo "Usage: bash Probe/build.sh [--unsigned] [--skip-tests]" >&2; exit 2 ;;
    esac
done
probe_build="$PWD/.build/probe"
probe_app="$probe_build/SelectEnglish.app"
mkdir -p "$probe_build"
if ! "$skip_tests"; then bash Probe/test.sh; fi
# A fresh staging bundle prevents old resources or runtime data from entering a build.
probe_stage="$(mktemp -d "$probe_build/stage.XXXXXX")"
trap 'rm -rf "$probe_stage"' EXIT
staged_app="$probe_stage/SelectEnglish.app"
mkdir -p "$staged_app/Contents/MacOS" "$staged_app/Contents/Resources"
probe_sdk="$(xcrun --sdk macosx --show-sdk-path)"
for arch in arm64 x86_64; do
    echo "Compiling $arch for macOS 13.0…"
    mkdir -p "$probe_build/module-cache-$arch"
    xcrun swiftc -sdk "$probe_sdk" -target "${arch}-apple-macosx13.0" \
        -module-cache-path "$probe_build/module-cache-$arch" \
        Probe/Sources/*.swift -framework AppKit -framework ApplicationServices \
        -o "$probe_stage/SelectEnglishProbe-$arch"
done
xcrun lipo -create "$probe_stage/SelectEnglishProbe-arm64" "$probe_stage/SelectEnglishProbe-x86_64" \
    -output "$staged_app/Contents/MacOS/SelectEnglishProbe"
xcrun lipo "$staged_app/Contents/MacOS/SelectEnglishProbe" -verify_arch arm64 x86_64
cp Probe/Info.plist "$staged_app/Contents/Info.plist"
# Only explicit repository documents are bundled; never copy a runtime directory.
for resource in LICENSE PRIVACY.md; do
    if [[ -f "$resource" ]]; then cp "$resource" "$staged_app/Contents/Resources/$resource"; fi
done
plutil -lint "$staged_app/Contents/Info.plist"
if ! "$unsigned"; then
    codesign --force --sign - --identifier com.selectenglish.probe "$staged_app"
    codesign --verify --strict "$staged_app"
    echo "Development ad-hoc build only: NOT Developer ID signed or notarized."
fi
rm -rf "$probe_app"
mv "$staged_app" "$probe_app"
echo "Built universal app: $probe_app"
