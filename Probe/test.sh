#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
probe_tests="$PWD/.build/tests"
mkdir -p "$probe_tests/module-cache"
swiftc -module-cache-path "$probe_tests/module-cache" Probe/Sources/GestureGate.swift Probe/Tests/main.swift -o "$probe_tests/gesture-tests"
"$probe_tests/gesture-tests"
swiftc -parse-as-library -module-cache-path "$probe_tests/module-cache" Probe/Sources/Analysis.swift Probe/Sources/Storage.swift Probe/Tests/Services/main.swift -framework Security -o "$probe_tests/service-tests"
"$probe_tests/service-tests"
