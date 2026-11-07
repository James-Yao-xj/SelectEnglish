# Implementation status — v0.5

## Approved scope
User approved Force Click feasibility followed by the native MVP. Force Click → full selection passed in TextEdit; user asked to continue. The application now includes AI configuration, translation/expression output and explicit local favorites.

## Completed
- [x] Initialize Trellis and GitHub private repository.
- [x] Document requirements, design, research and context manifests; activate task.
- [x] Verify AX manual selected-text capture with live TextEdit 50-character selection.
- [x] Research raw CG gesture → NSEvent pressure conversion from primary sources.
- [x] Verify real stage 2 and one trigger per gesture with standalone passive helper.
- [x] Integrate passive monitor and off-main AX capture; verify real Force Click → full50-character selection in v0.4.
- [x] Implement native AppKit menu-bar and result/settings/favorites/diagnostics windows.
- [x] Implement custom HTTPS chat completions, structured parsing, timeout, cancellation and stale-result guards.
- [x] Implement origin-bound Keychain credentials and nonsensitive preferences.
- [x] Implement explicit local favorites, atomic persistence, delete, corrupt-file protection.
- [x] Pass gate checks, mocked HTTP success/error/malformed/timeout/cancel, notebook reopen/delete/corruption tests.
- [x] Independent whole-MVP code review and compile passed.
- [x] Strict signature/plist checks passed.
- [x] CUA checked settings layout, empty-setting validation and empty favorites window.
- [x] v0.5 live process confirms AX authorized and passive monitor enabled after approved reauthorization.

- [x] User approved two work commits; pushed to GitHub main and verified remote feature SHA e167aef.

## Remaining
- [x] Physical Chrome Force Click → 40-character selected text captured by v0.5; no configured AI, no request sent.
- [ ] User fills their service configuration in application; real provider request remains unverified.
- [ ] Archive after the real-provider check is completed or explicitly deferred.

## Verification commands
- `bash Probe/test.sh`: gate and offline mock service/persistence checks.
- `bash Probe/build.sh`: build native application and ad hoc sign.
- `codesign --verify --strict .build/probe/SelectEnglishProbe.app`.
- `plutil -lint Probe/Info.plist`.

Do not rebuild the working signed application for documentation-only changes. Keep real-provider and browser checks separate from offline test results. Preserve the evidence in research/.
