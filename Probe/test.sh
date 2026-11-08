#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
probe_tests="$PWD/.build/tests"
mkdir -p "$probe_tests/module-cache"
swiftc -module-cache-path "$probe_tests/module-cache" Probe/Sources/GestureGate.swift Probe/Tests/main.swift -o "$probe_tests/gesture-tests"
"$probe_tests/gesture-tests"
swiftc -parse-as-library -module-cache-path "$probe_tests/module-cache" Probe/Sources/Analysis.swift Probe/Sources/Storage.swift Probe/Sources/NotebookMenuSelection.swift Probe/Tests/Services/main.swift -o "$probe_tests/service-tests"
"$probe_tests/service-tests"

swiftc -module-cache-path "$probe_tests/module-cache" Probe/Sources/PopupGeometry.swift Probe/Tests/Geometry/main.swift -o "$probe_tests/geometry-tests"
"$probe_tests/geometry-tests"

swiftc -module-cache-path "$probe_tests/module-cache" Probe/Sources/PopupDismissalState.swift Probe/Tests/Dismissal/main.swift -o "$probe_tests/dismissal-tests"
"$probe_tests/dismissal-tests"

swiftc -module-cache-path "$probe_tests/module-cache" Probe/Sources/PopupMouseEvent.swift Probe/Sources/PopupDismissalState.swift Probe/Tests/MouseEvent/main.swift -framework AppKit -o "$probe_tests/mouse-event-tests"
"$probe_tests/mouse-event-tests"
