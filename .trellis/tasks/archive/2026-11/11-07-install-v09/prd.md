# Install and publish v0.9
User explicitly requests installation, removal of old versions and GitHub update.
## Scope and acceptance
- Install the already-verified signed0.9 app at /Applications/SelectEnglish.app without rebuilding, resigning, changing bundleID or bundling credentials.
- Quit old running process through native UI before switching. Launch installed path and confirm version/processpath/permissions/settings; preserve current local API configuration and favorites.
- Move obsolete verified-v0.x backups, candidate binaries, duplicate exported/development app copies and older zip packages to recoverable Trash only after installed copy verified. Keep source, Trellis history, latest0.9 zip and all user runtime data.
- Update README with canonical installation path; publish private GitHub v0.9 release with current app zip and checksum. No connector release tool is available; use existing authenticated gh CLI.
- Verify remote commit/release assets and clean working tree. No application-code changes; no rebuild or extra API benchmark needed.
