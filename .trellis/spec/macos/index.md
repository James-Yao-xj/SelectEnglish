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
- `Storage.swift` owns per-user local credential files and atomic Codable notebook persistence. Corruption preserves the original file and blocks writes.
- `main.swift` owns native AppKit windows and one cancellation/generation boundary across AX capture and AI work. Closed windows never reopen from network results.
- Local credential data is bound to a normalized HTTPS origin via nonsecret preferences; changing providers requires a new key. Secure fields are never prefilled from storage and are cleared on close.
- `bash Probe/test.sh` exercises mock HTTP success, errors, malformed results, timeout/cancel and notebook persistence/delete/corruption without network.

## Dictionary popup presentation
- `ResultPopup.swift` owns the borderless nonactivating NSPanel and cached native kraft-paper background. Show only after AX capture or an explicit user open action; never on startup.
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

## Selection analysis latency contract
1. **Scope / trigger:** keep short learning queries responsive without changing selected-text schema or adding provider requirements to custom endpoints.
2. **Signatures:** `AnalysisClient.analyze(text:configuration:key:)` retains its contract; controller `analyze(bypassReuse:)` distinguishes physical recapture from explicit Retry.
3. **Request contract:** only exact case-insensitive host `api.deepseek.com` and exact models `deepseek-flash`/`deepseek-v4-pro` receive top-level `thinking: {type: disabled}`. Other host/model combinations omit it and `reasoning_effort`. Preserve exact configured HTTPS endpoint/model; no model substitutions or automatic retries.
4. **Validation / errors:** cached reuse requires valid configuration and origin binding, exact source/endpoint/model, and last completed success. A generation/cancel check must precede publishing and caching. Save settings/delete key clears reuse and invalidates tasks. Retry bypasses reuse; failure is never a new cached success.
5. **Cases:** Good: known official DeepSeek short task uses non-thinking. Base: arbitrary compatible provider gets its ordinary request. Bad: apply vendor parameters from a model prefix or hostname suffix; reuse across endpoint/model changes.
6. **Tests:** inspect serialized requests for both known models, uppercase official host, lookalike host, proxy host, and unknown/legacy model. Preserve existing live schema, timeout/cancel and historical persistence checks. Verify runtime reuse and new request timing separately from hardware trigger evidence.
7. **Wrong vs correct:** do not treat a UI observation timestamp as exact service duration or claim a percentage improvement from one request. Measure with monotonic uptime; display completed AI seconds and AX duration without logging source/key. Keep the single cached result in memory only; no disk cache or saved credentials in it.

### Credential wait must not block analysis UI (v0.8 lesson)
`KeyStore.readAsync(using:)` dispatches reads on one serial queue; tests inject a fake reader and never access live credentials. Publish waiting status before awaiting; analysisTask covers both credential lookup and HTTP. After lookup, check task cancellation and request generation before starting any HTTP call, and again before publishing/caching. Cancellation cannot dismiss an OS permission prompt, but the popup must remain responsive. Include credential wait in completed action duration; report AI duration separately. Do not bypass SecurityAgent or modify Keychain ACLs to hide ad hoc signing prompts. Never claim provider latency from a stack blocked in securityd before HTTP.

## Local credential storage revision (user-approved)
1. **Scope / trigger:** user explicitly chose local configuration instead of repeated Keychain password prompts. This supersedes the original Keychain implementation; old item remains untouched, no migration or ACL changes.
2. **Signatures:** `KeyStore.read(file: URL? = nil) throws -> String?`; `save(_:file:) throws`; existing `readAsync(using:)` retains background/cancellation semantics.
3. **Contract:** plaintext UTF8 at `~/Library/Application Support/SelectEnglish/Private/api-key`, outside repo. Directory0700 enforced before atomic replacement; final file0600. Missing returns nil; empty save deletes. Origin binding stays in nonsecret preferences. User re-enters once after upgrade; secure fields never prefill from storage.
4. **Validation / errors:** ignore only specific missing-file errors; invalid UTF8 and other I/O errors propagate visibly. Settings save/delete invalidates tasks and clears result reuse. Check generation/cancellation after async read before sending HTTP.
5. **Cases:** Good: user saves once locally and subsequent requests require no Keychain. Base: absent file prompts configuration and sends no AI. Bad: silently read old Keychain, store key in repo, or weaken system ACLs to hide prompts.
6. **Tests:** use injected temporary file URLs/fake values, not user credentials; missing/save/replace/reopen/delete, permissions on existing directory/replacement, UTF8/I/O failures. Preserve service/history/async cancel checks. Native single-sample timing and filesystem metadata are separate evidence; never read actual key through diagnostic tools.
7. **Wrong vs correct:** never log, prefill, embed or commit credential values. Store only in the per-user runtime directory, ignore accidental `Private/`/`api-key` copies, and scan source/history before push. Explicitly disclose local plaintext storage rather than calling it Keychain encryption.

## Installed delivery
The canonical installed app is `/Applications/SelectEnglish.app`. Copy the verified signed app without rebuilding, resigning or changing its bundleID. Verify the process executable path and current-process AX/input-listen permissions before moving source/duplicate app copies to recoverable Trash. Keep user Application Support data separate and untouched. Publish zip with root `SelectEnglish.app` and SHA256 companion; verify remote digest, intended repository visibility and release assets. Old verified-v0.x/candidate paths are historical evidence, not copies to retain indefinitely.

## Review regression contracts
1. **Scope / trigger:** prevent unrelated single-word vocabulary and stale AX callbacks after click-away; keep current offline/transmission documentation accurate.
2. **Signatures:** `Analysis.validated(source:)` must validate single-word correspondence; popup capture observation exposes generation-bound begin/complete/invalidate and shares one mouse-dismissal state between both event monitors.
3. **Contract:** normalize case and boundary punctuation only; retain internal hyphen/apostrophe and inflection. No-space punctuation-separated fragments are not single lexical words. During hidden pending AX, a later mouse-down cancels. Use event timestamp, not callback delivery time, to ignore the initiating click. Retain that cutoff after AX completion and AI-start invalidation, since an initiating event may arrive after a fast read. Completion for an older generation cannot clear current pending state.
4. **Validation/errors:** unrelated vocabulary fails live validation; historical favorites still decode without live validation. Dismissal invalidates controller generation before any late AX result can show or invoke AI. No broader event masks or global keyboard monitoring.
5. **Cases:** Good: Happy! matches happy. Base: simple multiword sentence may have no vocabulary. Bad: Happy matches banana, or hidden AX work completes/shows/sends after a later click-away.
6. **Required tests:** wrong/empty single-word entry, case/boundary punctuation, internal connectors and inflection, no-space fragments; production dismissal state for hidden pending, original event delivery ordering, visible inside/outside, cancellation and superseded callbacks. Existing HTTP/history/storage/geometry/gate regressions remain.
7. **Wrong vs correct:** do not infer pending work from panel visibility or describe the current executable as offline-only. Track capture separately, preserve generation checks, and distinguish offline tests/manual diagnosis from configured automatic AI requests in current docs.

## Kraft-paper presentation
The popup uses a cached deterministic256px native bitmap tile, warm opaque beige, low-alpha grain/fibers and dark-brown primary/secondary ink. Keep rounded clipping/rim/shadow and current layout unchanged. Apply light appearance only to the paper popup, including icons/footer and attributed result foregrounds, so system dark appearance cannot produce white text on light paper. Do not regenerate texture on each refresh or add runtime media/network dependencies. Visual-only changes need candidate compile and native visual inspection, not cosmetic unit tests; preserve all event/capture/AI/storage state.

## Full-audit identity and event-position contracts
1. **Scope / trigger:** UI list order can change after a saved favorite is prepended; event delivery can lag behind pointer movement.
2. **Signatures:** `NotebookMenuSelection.item(for:title:) -> NSMenuItem` binds UUID; `entry(for:in:) -> SavedAnalysis?` resolves it. `PopupMouseEvent.screenPoint(for:) -> NSPoint` returns recorded AppKit screen coordinates.
3. **Contracts:** picker `representedObject` stores UUID, not row position/title. Refresh after successful save and retain selected UUID if present. Display/delete resolve only the represented ID. Mouse containment uses `event.window.convertPoint(toScreen: event.locationInWindow)` or nil-window event screen point, never current `NSEvent.mouseLocation`.
4. **Validation / errors:** missing/stale/untyped menu identity resolves nil and must not fall back to a different array entry. Save failure leaves prior notebook state; delete uses resolved UUID. Keep mouse timestamp cutoff and generation rules unchanged.
5. **Cases:** Good: displayed A stays A after inserting C; deleting A preserves C. Base: missing selection has no target. Bad: same title/current index used as record identity, or queued outside click considered inside after pointer moves.
6. **Tests:** production NSMenuItem helper with fake persisted records A/C, duplicate titles, old selected item after prepend, delete/reopen and removed-ID nil. Synthetic nil-window NSEvent points including negative coordinates through production mouse helper/dismissal state; no event posting or actual windows.
7. **Wrong vs correct:** never delete `entries[picker.indexOfSelectedItem]`; use record identity and refresh. Never classify a delivered mouse-down using current pointer position; use the event's recorded point. Native window conversion and physical input remain runtime QA separate from offline model tests.

## CET-6 vocabulary policy
For sentence/fragment analysis, the prompt targets a CET-6 reader: prefer CET6-or-harder words, academic/technical terms and uncommon contextual senses; omit basic/high-frequency ordinary/CET4-level senses, keep0–8 and no forced minimum. Return original source forms/contextual POS/Chinese meanings. This is approximate model judgment, not certified official word-list membership. Single-word selection always includes its own entry regardless of familiarity; strict correspondence validation remains. Do not rewrite historical favorites or claim prior entries were reclassified. JSON, sentence and fixed-expression contracts unchanged. A fresh application process clears the one-entry result reuse after prompt updates.

## Public beta distribution and onboarding
- `bash Probe/build.sh [--unsigned] [--skip-tests]` stages a fresh canonical `.build/probe/SelectEnglish.app`, explicitly compiles arm64/x86_64 for macOS13.0, and only bundles allowlisted LICENSE/PRIVACY.md. Universal compilation is not native hardware, oldest-OS, or Gatekeeper download evidence.
- `bash Probe/release.sh --beta|--formal` requires explicit mode. Formal requires `SIGNING_IDENTITY` (Developer ID Application name) and `NOTARY_PROFILE` (existing notarytool profile); require runtime/timestamp signing, Accepted submission, ticket stapling and validation, Gatekeeper assessment, then final ZIP/extraction validation/SHA. Missing identity or failed gates must stop, never fall back to beta. Beta artifacts are ad-hoc and must be prereleases. Do not weaken Gatekeeper or remove quarantine for QA.
- CI on `macos-15` and `macos-15-intel` uses no secrets and read-only contents permissions; it validates offline behavior/builds on both architectures, not physical Force Touch or pristine download startup.
- `OnboardingPolicy.shouldShowAutomatically` uses only nonsecret seen/endpoint/model/origin preferences. Fresh unconfigured users see help once; any prior partial configuration or seen flag suppresses automatic help on upgrade. Both menus reopen it. Only explicit permission buttons request access. Live help status distinguishes AX trust, input access, tap creation and enabled state; no credential reads to determine onboarding.
- Distribution readiness evidence belongs in `docs/RELEASE-CHECKLIST.md`; model sample observations in `docs/evaluation/`. Record unresolved certificate, second-device and minimum-OS gates explicitly. Preserve original bundle identity and runtime data for installed upgrades; do not replace a working authorized app simply to test unrelated documentation.

## Browser PDF selection extraction
1. **Scope:** `SelectionReader` adapts AX to `SelectionExtraction<SelectionAccess>` on the existing serial capture worker; original source process identity and controller generation remain authoritative.
2. **Selection contract:** prefer focused AXSelectedText, then same-node nonempty AXSelectedTextRange/AXStringForRange or selected TextMarker length/string. Require range/marker UTF16 length equality and max20k. The direct AX path never uses AXValue, clipboard, OCR or whole-document text. The user-approved separate opt-in browser copy path below supersedes the original blanket no-clipboard convention.
3. **Hierarchy:** descendant search requires focused/nearest-ancestor PDF proof (.pdf URL, exact Chrome built-in viewer extension origin, AXPDFDocument). Reject AXWindow/Application before proof; never scan window siblings/background tabs. Skip descendant toolbar/editable controls so retained page/zoom/annotation selection cannot substitute for PDF content. A directly focused editable selection remains valid.
4. **Bounds/errors:** max80 visited nodes, depth8,256 algorithm calls and1.5s native total (including focus/diagnostics), per-AX timeout at most0.08s. Cycle detection and process-liveness checks are mandatory. Preserve substantive AX error names/raw codes on failure; expected unsupported/noValue must allow compatible selection fallback. Budget exhaustion is a failure, never a partial whole-document result.
5. **Cases:** Good: PDF viewer root with nested selected content; Base: empty/scanned/unexposed selection fails with empty current text. Bad: stale page-field1 returned instead of PDF selection, PDF URL on AXWindow opening a whole-window scan, or range2 returning full document.
6. **Tests:** production algorithm/fake adapter covers direct/range/markers, invalid/mismatched/oversized ranges, PDF scope, window/page exclusions, stale editable controls, cycles/budgets/deadlines/process termination. Existing suite + full universal compile. Native browser and physical ForceClick evidence must be recorded separately from algorithm tests.
7. **Delivery:** fix branch/candidate is distinct from published0.10.0-beta.1; do not claim a released asset contains PDF support until actually released. No browser/platform guarantees without actual native selection evidence.

## User-approved opt-in browser copy fallback
- `selection.browserCopyFallback` defaults false; explicit settings checkbox persists the decision independently of AI configuration. The user approved enabling it for custom PDF viewers that expose no AX text (2026-11-11). All public/app privacy descriptions must distinguish default directAX from opted-in temporary clipboard use; never call this encrypted or guaranteed invisible to clipboard managers.
- Only a physical automatic capture with failed directAX may enter fallback. Manual diagnostics remain AX-only. Bind known browser bundle/PID/launch date/frontmost identity, controller generation and thread-safe permit before each native menu request/action, clipboard mutation, publishing and HTTP start. Wait for mouse release within a bound. Never activate another app or broaden input monitoring.
- Prepare a source-bound copy handle and bounded mouse-release wait before clipboard mutation. Create both fixed Command-C events before any key posting; creation failure inside the clipboard transaction must restore its snapshot. The user confirmed manual Cmd+C works while native closed-menu AXCopy yielded no text: the opt-in fallback sends Cmd+C down/up via public CGEvent.postToPid only to the original browser. Check source/permit before keydown, always send keyup cleanup to that original PID, never systemwide-post, activate apps or add keyboard listeners. `ClipboardSelectionTransaction` snapshots all existing item/type bytes within32items/64types/8MiB, aborts before mutation on incomplete backup, clears to exclude stale old content, requests fresh copy and polls with a bound. Empty/oversized/error/cancel never sends old clipboard text to AI.
- Restore the snapshot only if clipboard version still equals the transaction's observed version. Preserve subsequently observed external changes. General clipboard has no writer identity or atomic compare-and-restore; first post-command attribution and restoration are best effort, not a concurrency/security guarantee. Document manager history and other-copy races. No clipboard data or private PDF URLs in logs/tests/repo evidence.
- Fake-only tests cover lossless types, backup failure before effects, copy errors/no-write/empty/oversize, timeout, generation and task cancellation, concurrent version change, source allowlist/identity, exact targeted shortcut intent and mandatory key-up cleanup. Never instantiate native clipboard adapter in tests. Compile and independently review before final sign/install; native custom-viewer copy/translation remains a distinct gate.

## PDF gesture-order verification
ChromePDFium clears a prior selection on new leftMouseDown before pressurestage2; singleclick can leave zero-lengthrange. Thus a validatedAX/clipboardpipeline cannotrecovertextalreadyclearedbythebrowser. Actualtargetviewermustbeconfirmedatgesturetime, notinferredfromlaterforegroundtabs. Beforeanotherfallback/rebuild, compareselectedtextwithoutanewPDFclick againstaftergesture; checkhighlightretention and consideranoutside-bodytriggerorworddoublepresscontrol. Do notsilentlypre-copyordinaryselections orbroadenmonitoring. Userapprovedcopyfallbackonlyafterphysicaltrigger; advancecapture/newtrigger requiresanexplicitproduct/privacydecision. Syntheticintent tests neverprovebrowserselectionretention.
