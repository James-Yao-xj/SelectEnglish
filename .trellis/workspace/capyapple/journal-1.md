# Journal - capyapple (Part 1)

> AI development session journal
> Started: 2026-11-07

---



## Session 1: Native Force Click MVP v0.5
<!-- trellis-session: v=2 fp=68bae43a35ec2ca2 -->

**Date**: 2026-11-07
**Task**: Native Force Click MVP v0.5
**Branch**: `main`

### Summary

Implemented and pushed native macOS selection translation app; actual TextEdit and Chrome Force Click capture passed.

### Main Changes

- Passive CG gesture-to-pressure conversion, off-main AX capture, native AI settings/results/favorites, origin-bound Keychain credentials.

### Git Commits

| Hash | Message |
|------|---------|
| `a5b82c8` | chore: initialize Trellis workflow |
| `e167aef` | feat: add Force Click translation and expression notebook |

### Testing

- [OK] Four gesture checks, mock HTTP success/errors/timeout/cancel, notebook persistence/delete/corruption, independent review/compile, strict signature/plist, CUA live TextEdit50 and Chrome40 capture.

### Status

[OK] **Completed**

### Next Steps

- User enters endpoint/model/key in application; verify real provider before task archive.


## Session 2: Dictionary-style popup v0.6
<!-- trellis-session: v=2 fp=91bb582eaa17b328 -->

**Date**: 2026-11-07
**Task**: Dictionary-style popup v0.6
**Branch**: `main`

### Summary

Replaced large result window with a native dictionary-like popup at the Force Click position.

### Main Changes

- Compact nonactivating panel, native material, bounded multi-screen placement, menu-only startup, local Esc and outside-click dismissal.

### Git Commits

| Hash | Message |
|------|---------|
| `2089093` | feat: show translations in dictionary-style popup |

### Testing

- [OK] Independent compile/review, geometry and regression suites, native visual inspection, Esc/outside-click via inventory, actual authorization/monitor enabled.

### Status

[OK] **Completed**

### Next Steps

- User-configured real AI service validation remains pending; keep active MVP task open.


## Session 3: Vocabulary-first learning popup v0.7
<!-- trellis-session: v=2 fp=76fa4c6630b123e6 -->

**Date**: 2026-11-07
**Task**: Vocabulary-first learning popup v0.7
**Branch**: `main`

### Summary

Completed vocabulary POS/meaning, sentence explanation, then genuine fixed expressions; real DeepSeek public-sample response verified in the compact native popup.

### Main Changes

- Preserved historical favorites and added strict live schema tests; restored explicitly authorized Accessibility and Input Monitoring for the frozen build.

### Git Commits

| Hash | Message |
|------|---------|
| `94376d7` | feat: explain vocabulary before sentence and fixed expressions |

### Testing

- [OK] Independent review, offline service/storage/geometry checks and strict app signature/plist checks passed; real popup response and timeout listener recovery observed.

### Status

[OK] **Completed**

### Next Steps

- Collect user feedback on vocabulary selection and popup readability.


## Session 4: Reduce analysis latency and unblock credential wait
<!-- trellis-session: v=2 fp=0eaa182fed133f56 -->

**Date**: 2026-11-07
**Task**: Reduce analysis latency and unblock credential wait
**Branch**: `main`

### Summary

Explicit non-thinking for official DeepSeek models, concise output, exact last-result memory reuse and asynchronous credential reads; final native acceptance pending protected SecurityAgent handoff.

### Main Changes

- Added total/AI and AX timing, retry bypass, settings invalidation and removal of redundant key-presence decrypt reads.

### Git Commits

| Hash | Message |
|------|---------|
| `4fd53ef` | perf: reduce analysis reasoning and avoid blocking credential reads |

### Testing

- [OK] Offline suite, 10 serialized provider boundary cases, fake-reader background/cancellation regression and independent whole candidate compilation passed.

### Status

[OK] **Completed**

### Next Steps

- User dismisses old Keychain system prompt; install final candidate and measure real public-sample response. Keep task in progress; no measured speedup claimed.


## Session 5: Local API configuration without password prompts
<!-- trellis-session: v=2 fp=9591583b6430cbf5 -->

**Date**: 2026-11-07
**Task**: Local API configuration without password prompts
**Branch**: `main`

### Summary

Replaced Keychain with user-approved per-user local credential file, preserving origin binding and latency fixes; final v0.9 native real-provider request passed without password prompt.

### Main Changes

- File directory0700/file0600, atomic save/delete, no Keychain migration or secret export; local-copy app and v0.9 zip updated.

### Git Commits

| Hash | Message |
|------|---------|
| `51b11f1` | fix: use local API configuration without keychain prompts |

### Testing

- [OK] Temporary fake-key file persistence/permissions/errors, all offline regressions, independent compile/review and strict signing/plist passed. User saved key in native settings; public80-char sample AX0.01s and AI1.9s. Only actual-file metadata read by tools.

### Status

[OK] **Completed**

### Next Steps

- Gather user feedback on everyday popup responsiveness; single-sample timing is not a guarantee.


## Session 6: Install v0.9, clean old copies and publish release
<!-- trellis-session: v=2 fp=8ae6e3437b9a6e25 -->

**Date**: 2026-11-07
**Task**: Install v0.9, clean old copies and publish release
**Branch**: `main`

### Summary

Installed canonical /Applications/SelectEnglish.app, verified running path and native permissions, moved14 obsolete/duplicate app/package artifacts to recoverable Trash, and published private GitHub v0.9 release.

### Main Changes

- Updated install docs; user runtime credentials/favorites untouched. ZIP contains canonical SelectEnglish.app and SHA256 companion.

### Git Commits

| Hash | Message |
|------|---------|
| `3213826` | docs: record installed v0.9 and GitHub release |

### Testing

- [OK] Verified identical signed executable, strict codesign, current-process AX/input allowed+tap enabled, active-location inventory and GitHub asset digest match. No code rebuild or API request.

### Status

[OK] **Completed**

### Next Steps

- Use installed menu-bar app; future updates replace only the application bundle.
