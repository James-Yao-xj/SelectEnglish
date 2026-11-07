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
- [x] User configuration stored locally; real DeepSeek response verified in the v0.7 popup with a public sample.
- [x] Real-provider check completed; ready for Trellis archive.

## Verification commands
- `bash Probe/test.sh`: gate and offline mock service/persistence checks.
- `bash Probe/build.sh`: build native application and ad hoc sign.
- `codesign --verify --strict .build/probe/SelectEnglishProbe.app`.
- `plutil -lint Probe/Info.plist`.

Do not rebuild the working signed application for documentation-only changes. Keep real-provider and browser checks separate from offline test results. Preserve the evidence in research/.

## Current authorized refinement: dictionary-style popup
- [x] Replace large result window with compact native floating panel, anchored to trigger pointer.
- [x] Remove automatic result window on launch; keep menu bar entry.
- [x] Add bounded placement and scrollable translation/expression layout, outside-click/Esc/close dismissal.
- [x] Verify cancellation and late response cannot reopen the popup; keep AI/settings/storage behavior unchanged.
- [x] Compile and independently review; check actual native popup layout, settings/diagnostics access, Esc and outside-click with CUA.

## Dictionary presentation refinement checkpoint
- v0.5 preserved at `.build/verified-v0.5/` before rebuilding.
- Compact NSPanel, native material, pointer anchor, screen bounds, local Esc/outside dismissal and cancellation implemented; no startup result window.
- Core service tests and geometry tests passed; candidate full compilation passed.
- Final signed v0.6 will be frozen for main-session native visual QA; no real user-configured AI request was made by implementer.

## Current authorized refinement: learning content order
- [x] Update typed AI contract/prompt/validation for contextual vocabulary POS/meaning, sentence explanation and genuine fixed expressions.
- [x] Preserve old notebook decoding and distinguish historical missing fields.
- [x] Update popup and notebook formatting to the user order.
- [x] Add meaningful structured response/order/legacy compatibility tests; build and independently review.

## v0.7 validation checkpoint
Learning sections are shared by popup and notebook in the exact order 生词 → 整句解释 → 固定表达. Isolated word analysis requires a word/POS/meaning entry; explanations acknowledge absent sentence context. Live responses cannot silently use the historical schema. Legacy favorites remain decodable and are not rewritten on open; temporary-file tests cover new/legacy mixed saves. Core credentials, real user settings and provider were not accessed during tests. Final native visual QA remains owned by main session after signed build.

## Runtime diagnosis and cancellation label correction
Actual v0.7 diagnostics showed a created but disabled tap after prior event delivery; exact reason was not previously retained, so no timeout or permission cause is claimed. Added actual input-listen access, created/enabled state, per-start reset counters and disabled reason/counts. Recovery is restricted to the documented timeout callback; user/system disable requires manual action.
CUA/user outside dismissal cancelled an in-flight known-sample request but retained its loading text. Updated dismissal to show cancelled/retry when an AI task was active, without reopening or changing a completed result. Final regression/build/sign follow this bounded correction.

## Final native acceptance
- [x] User approved restoration of Accessibility and Input Monitoring; current signed app reports both allowed and tap enabled.
- [x] Observed one real timeout and successful enabled listener afterward.
- [x] Real DeepSeek public-sample response visibly displayed vocabulary POS/meaning → sentence translation/explanation → fixed expressions in the compact popup.
- [x] Final CUA complete; signed build frozen, no code changes after restored authorization.
See `research/learning-order-check.md` for separate hardware-capture and real-provider evidence.
