# macOS Development Guidelines

## Pre-Development Checklist
- Read the active PRD, design, implementation plan, and research.
- Use Swift and public AppKit / ApplicationServices APIs for the feasibility probe.
- Keep diagnostics offline. Send selected text only to a valid user-configured HTTPS AI endpoint. Persist text only when the user saves a favorite. Never record text or keys in logs.
- Use English interface and implementation comments. Product-facing instructions can be Chinese.
- Separate event detection from selection capture. Capture before activating the probe window.

## Quality Check
- Compile using the installed Swift compiler.
- Check single-trigger behavior per pressure gesture and reset on release.
- Report AX errors explicitly; never present stale selection as current.
- Verify physical Force Click in TextEdit and a browser with user assistance.
- Do not claim global pressure delivery from a local-window test.
- Physical TextEdit and Chrome Force Click selection passed in v0.4/v0.5. Native popup presentation and dismissal passed separately in v0.6. A real DeepSeek public-sample response and the three learning sections passed in v0.7; provider QA and physical capture are separate evidence.

## Probe conventions
- `Probe/Sources/GestureGate.swift` triggers once at stage 2 and resets at stage 0 or mouse-up. Reversing from stage 2 to stage 1 must not rearm.
- `Probe/Sources/main.swift` uses a passive CGEvent session tap for global gesture-wrapper conversion and an NSEvent local monitor for diagnostics. Only a global trigger reads the front application's selected text. Local counts are diagnostic evidence only.
- Clear the previous text before each AX read so failures cannot display stale text. Do not activate the probe during capture.
- Global NSEvent monitors cannot suppress the target app's actions. Physical testing must record simultaneous system lookup behavior.
- `bash Probe/build.sh` runs 4 gate checks and builds an ad hoc signed app. It does not validate hardware delivery or AX compatibility.

## Development authorization check
System Settings may show an enabled entry while the current ad hoc build reports AXIsProcessTrusted false. Verify trust in the running process, and identify the precise app copy when duplicate bundle IDs exist. Permission changes require user authorization. Avoid rebuilding a working authorized probe solely for documentation changes. For deterministic manual AX diagnosis, choose the target application explicitly instead of inferring it after a timer; keep real gesture capture tied to the actual foreground app.

## Event tap and AX boundary
- The passive session tap uses mouse down/up/drag plus AppKit gesture/pressure raw masks; never include keyboard events. Raw-to-AppKit mapping is empirically verified on this Mac, not a universal platform promise.
- At stage 2, capture the source NSRunningApplication before dispatch. Do not resolve frontmost again on the worker queue.
- `SelectionReader.swift` performs AX on a serial worker; check process identity and return plain text/metadata results. UI updates stay on main and use a generation guard.
- Never perform AX or network work inside an event tap callback.
- A detected Force Click and a successful full-selection read are separate acceptance gates. No selection is a valid failure outcome, not permission to cache a whole document.

## MVP conventions
- `Analysis.swift` owns the OpenAI-compatible request, normal JSON-content parsing, HTTP/body-safe errors and redirect refusal. Full endpoints are not joined with extra `/v1` segments.
- `Storage.swift` owns Keychain and atomic Codable notebook persistence. Corruption preserves the original file and blocks writes.
- `main.swift` owns native AppKit windows and one cancellation/generation boundary across AX capture and AI work. Closed windows never reopen from network results.
- Keychain data is bound to a normalized HTTPS origin via nonsecret preferences; changing providers requires a new key. Secure fields are never prefilled from Keychain and are cleared on close.
- `bash Probe/test.sh` exercises mock HTTP success, errors, malformed results, timeout/cancel and notebook persistence/delete/corruption without network.

## Dictionary popup presentation
- `ResultPopup.swift` owns the borderless nonactivating NSPanel and native popover material. Show only after AX capture or an explicit user open action; never on startup.
- Snapshot pointer with source app at pressure stage 2. `PopupGeometry.swift` selects the containing full screen before clamping to its visibleFrame; handle negative-origin and adjacent monitors.
- Keep AX diagnostics in the status window. Popup messages use actionable plain language, not AX names or stage counts.
- A nonactivating key panel accepts local Esc/copy without NSApp.activate. Outside local/global mouse clicks dismiss and invalidate in-flight AX/AI work. No global key monitor is added.
- Network updates refresh the retained anchor without ordering a dismissed panel front. Settings, notebook, and diagnostics remain menu-bar windows.

## Learning response and historical favorites
- Live Analysis requires vocabulary entries (word, contextual partOfSpeech, meaning), translation, sentenceExplanation and expressions. Use 0–8 vocabulary items and 0–5 genuine fixed expressions; a single selected word must include its vocabulary entry even when common.
- Optional vocabulary/sentenceExplanation values represent missing historical data only. Decode old favorites without live validation or implicit migration. Never replace missing historical fields with invented analysis.
- `Analysis.displaySections` supplies the shared 生词 → 整句解释 → 固定表达 order for attributed popup and plain notebook. Label historical expressions honestly when the old response did not distinguish fixed collocations.
- Tests cover strict new live schema, contextual POS, legitimate empty arrays, isolated words, legacy opening without writes and mixed old/new notebook roundtrip.

## Runtime tap and dismissal diagnostics
- Expose current-process CGPreflightListenEventAccess, tap creation/enabled state, per-start counters and exact timeout/user-input disable metadata in diagnostics only. AX trust is not proof of active input listening.
- Only an explicit tapDisabledByTimeout event permits automatic tapEnable(true). Do not recover automatically from tapDisabledByUserInput or request broader permissions.
- Reset counters on each explicit listener start so old delivery cannot be mistaken for current installation evidence.
- Dismissing an in-flight AI result cancels and invalidates it, and changes the retained loading label to cancelled/retry. Explicit reopening must not falsely look like the old request is still running.

### Learning contract reference
1. **Scope / trigger:** live AI schema now includes learning vocabulary and sentence explanation; old notebooks remain readable.
2. **Signatures:** `Analysis.validated(source: String? = nil) throws -> Analysis`; `Analysis.displaySections` is shared by both presentations.
3. **Contract:** live JSON includes `vocabulary: [{word, partOfSpeech, meaning}]`, `translation`, `sentenceExplanation`, and `expressions: [{phrase, meaning, usage, example}]`. Vocabulary is 0–8; expressions 0–5. Nonempty single-word input requires vocabulary.
4. **Validation/errors:** missing live learning fields, blank entry/POS/meaning, or over-limit arrays fail validation. Missing historical optional fields decode without fabricated content. Empty expression arrays are valid.
5. **Cases:** Good: contextual vocabulary and genuine idioms. Base: simple sentence with empty vocabulary/expressions. Bad: old live schema accepted as a new analysis.
6. **Required tests:** new schema acceptance, invalid fields rejected, section order, isolated-word requirement, legacy read without write, mixed historical/new save and reopen.
7. **Wrong vs correct:** do not call live validation on old notebook records or silently default missing live fields. Decode history as history; validate new AI responses before display/save.
