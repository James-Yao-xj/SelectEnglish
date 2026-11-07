# Patch0.9.1 verification
## Automated
All existing offline gate/services/storage/history/geometry checks passed, plus selected-word correspondence and shared production dismissal-state regressions. Independent whole-app candidate compilation/review passed. A discovered fast-AX edge was fixed: initiating-event timestamp cutoff survives capture completion and AI-start invalidation. No global event mask or keyboard access change.
## Build/install
Final0.9.1/build10 signed app built; strict codesign and plist checks passed. Installed at canonical /Applications/SelectEnglish.app, former0.9 moved recoverably to Trash. User configuration/key/notebook not accessed or changed. Patch app launched successfully. User completed the macOS confirmation. Final running patch diagnostics directly confirmed AX authorized, InputMonitoring allowed, tap created/enabled with current events. System-requested restart completed; app left running in menu bar. No real provider/hardware slow-AX test performed for this patch; deterministic regressions use synthetic timestamps/state, no user data or network.
## Release preparation
Canonical SelectEnglish.app ZIP and SHA256 sidecar prepared outside source tree; source credential-pattern scan zero. Actual key value never read by a tool or included in artifacts.

## Final release/cleanup
Published non-draft private GitHub patch: https://github.com/James-Yao-xj/SelectEnglish/releases/tag/v0.9.1 . ZIP198645bytes and SHA256 companion91bytes. Remote digest matches local `b8aed944ebb7e9a0a33f0f6f99b6f081ee7a7b927bfd78cc681723d1b16725ea`. Local obsolete0.9 ZIP/sidecar and generated duplicate build/candidate moved recoverably to Trash. Only canonical installed app remains active; local configuration/favorites untouched. No signed rebuild after permission restoration.
