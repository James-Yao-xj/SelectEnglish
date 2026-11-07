# Patch0.9.1 verification
## Automated
All existing offline gate/services/storage/history/geometry checks passed, plus selected-word correspondence and shared production dismissal-state regressions. Independent whole-app candidate compilation/review passed. A discovered fast-AX edge was fixed: initiating-event timestamp cutoff survives capture completion and AI-start invalidation. No global event mask or keyboard access change.
## Build/install
Final0.9.1/build10 signed app built; strict codesign and plist checks passed. Installed at canonical /Applications/SelectEnglish.app, former0.9 moved recoverably to Trash. User configuration/key/notebook not accessed or changed. Patch app launched successfully. Native privilege restoration is pending user's macOS Touch ID confirmation; never claim permissions ready until observed. No real provider/hardware slow-AX test performed for this patch; deterministic regressions use synthetic timestamps/state, no user data or network.
## Release preparation
Canonical SelectEnglish.app ZIP and SHA256 sidecar prepared outside source tree; source credential-pattern scan zero. Actual key value never read by a tool or included in artifacts.
