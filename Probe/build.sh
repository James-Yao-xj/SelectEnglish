#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
probe_build="$PWD/.build/probe"
probe_app="$probe_build/SelectEnglishProbe.app"
mkdir -p "$probe_app/Contents/MacOS" "$probe_build/module-cache"
echo "Running application checks…"
bash Probe/test.sh
echo "Building SelectEnglish…"
swiftc -module-cache-path "$probe_build/module-cache" Probe/Sources/*.swift -o "$probe_app/Contents/MacOS/SelectEnglishProbe" -framework AppKit -framework ApplicationServices
cp Probe/Info.plist "$probe_app/Contents/Info.plist"
codesign --force --sign - --identifier com.selectenglish.probe "$probe_app"
echo "Built: $probe_app"
