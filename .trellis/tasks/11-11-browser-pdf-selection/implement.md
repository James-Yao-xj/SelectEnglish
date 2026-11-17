# Plan
- [x] Investigate browser PDF AX API shape and implement narrowly scoped capture support.
- [x] Regression tests and full universal build; independent review.
- [ ] Public synthetic browser PDF native selection QA when feasible; document actual limits.
- [ ] Update spec/docs, commit and push fix branch, retain task if real blocker unresolved.

## Current handoff
Work commit d1a4157 pushed to fix/browser-pdf-selection. Seven offline groups, independent review, full universal signed0.10.1/build14 passed. GitHub43000445954 passed on macos-15 and macos-15-intel. Installed /Applications/SelectEnglish.app0.10.1 signedcandidate; prior0.9.3 retained in Trash. Reset old same-identity TCC records; nativecurrentprocess confirms AXauthorized, inputallowed, listenercreated/enabled. No source edits after signing.
Baseline0.9.3 failed manual Chrome read on W3Cdummy.pdf selectedDummy. Candidate nativePDF read/physicalForceClick NOT yet proven. UseractivelyswitchesChrome back tovideo duringautomatedselection, so rootstoppedcompetingwithuserUI and requested once viaasync physicaltest: selectDummy inChrome dummy.pdf,ForceClickrelease,reply已重按. Awaitingresponse. No realAPIkeyread, no AI test request sent inthis task. Do notarchiveorclaimworkingPDFuntilactualnativeevidence. CUAhand-off remainspending; completion_summary notyetemitted.

## Copy fallback revision checkpoint
User explicitly approved opt-in clipboard fallback after real attempt used a custom canvas-based reader (not built-in W3C viewer), which exposed page groups but no selected text. No private URL/content persisted. Added nativeCopy menu adapter + defaultOFF setting + bounded clipboard transaction, with nine fake-only groups and independentcompile/review PASS. Observer-version overwrite and cancellation ownership bugs found/fixed before final signing. 0.10.2/build15 signed universal candidate installed at canonicalpath;0.10.1 movedtoTrash, runtimecredentials/notebookuntouched. GUIenabled selection.browserCopyFallback=true perexplicituserapproval. CurrentprocessnativeAXauthorized/inputallowed/tapcreated+enabled. No re-sign/rebuildafterpermissions.
Requested userphysicaltest inoriginalcustomPDF again aftercopyenable; awaiting已重按. Do notclaimactualcopy/nativePDFsuccessyet. Source/docs/specupdateduser-approvedclipboardexception with best-effort restore/firstwriterlimits. ManualdiagnosticremainsAXonly.

## Native copy attempt outcome
User physicaltest on0.10.2 returned nofreshcopytext via UI, no sections; no privateclipboardtext read bytools. This does NOTprove scannedPDF. Investigate closed-menu AXPress dispatch versuscustomviewer keyboard-onlycopy versuslostselection beforemaking moreblindbuilds. Userasked once whethermanual Cmd+C/paste works withoutforce todisambiguate. Nativebuilt-inW3Ccandidate remainsunverifiedseparately. Sourceerrorwordingchangedto neutral nofreshcopytext. Do notarchiveorclaimsuccess.

## Targeted shortcut revision checkpoint
Manual Cmd+C/paste confirmed by user. Changed appfeature to fixed C keyCode8+Command down/up viaCGEvent.postToPid(originalbrowserpid); oldAXmenu code removed. Ninefake/offlinegroups, universalbuild/signature and independentreview PASS. Native0.10.3/build16 installed withpreviouscandidateinTrash. CurrentprocessAX/inputauthorized/listenercreated+enabled; copyFallbackpref1 confirmed; noresignafterpermissions. Awaitinguserphysicaltest inactualPDFkeepingbrowserforegrounduntilresult. Synthetictests doNOTprovebrowserconsumption/selectionsurvival. No selectedprivateparagraph, privatePDFURL orclipboardbackupdata persisted.

## External UI blocker
LatestCUA read returned Macislocked/automaticunlockunavailable. Requested usermanualunlock; no attempttobypassauth. Final0.10.3nativePDFresultnotobserved. Keep taskinprogress/hand-offpending; CUAcompletion_summarymustwaituntilunlock/testoutcomeobserved. Sourcecommitc5b11c0 pushed; sourceunchangedafterfinalsignedinstall.

## Selection-clearing root-cause checkpoint
Afterunlock0.10.3physicalteststillnofreshcopy. ActualtargetthenconfirmednativeChromePDF; nohighlightaftertest. PrimaryChromiumOnLeftMouseDownclear+singleclickzero-range explainslossofpreselectedtextbeforestage2. Do notclaimrootfixedorcanvas-onlyproblem. UserpauseChromequestionwas superseded: latestrequest asksselecttextthenForceClickPDFtoolbarblankoutsidebody, avoidingpluginmousedown. AwaitingactualUIresult. Source/runtimeunchanged; no furtherrebuildbeforecontrolledevidence. Researchchrome-selection-order.md andspecupdatedfail-looplesson.


## Autonomous window checkpoint (2026-11-17)
The user's explicit ten-hour autonomous instruction supersedes all prior pending questions and handoffs in this chronological log. Do not ask for physical clicks, unlock, routine commits, or planning confirmation during this window. Start13:22:20UTC, deadline23:22:20UTC; see autonomous-2026-11-17.md.

- Implemented v0.11.0/build17 menu and registered selection hotkey, clipboard preview confirmation, original-event deferred cancellation, source vocabulary correspondence, and nonsecret release evidence.
- Independent code review passed. First integrated beta passed11 offline groups and universal/package verification, but was superseded by the additional scoped-PDF preview policy; do not install the earlier ZIP.
- Scoped PDF candidates now carry possible-incompleteness confirmation through the native adapter, controller and action router. Focused tests and joint candidate compile passed; final clean source/package/CI checks still pending.
- Source and49-commit history credential-pattern scan found zero matches; no runtime credential or notebook file read.
- Native automation timed out repeatedly, including inventory. No successful candidate PDF capture or native hotkey/menu claim. Current installed app remains0.10.3/build16 at canonical path; no unattended permission/authentication changes attempted.
- Next: commit reviewed changes in logical groups, build clean-source beta, push fix branch, verify both CI runners, and retry native QA only when computer-use connection recovers. Keep main and public stable releases unchanged.

## Cancelled-read latency checkpoint (2026-11-17)
Implemented shared SelectionCapturePermit for the AX worker and copy continuation; invalidation now stops obsolete queued/active AX operations cooperatively instead of only suppressing publication. Existing per-call timeout still bounds an issued call; no forced-interrupt claim. Version0.11.0 build18. Focused deterministic cancellation/selection/copy tests and unsigned candidate compile passed; no app install, signing, runtime permission or user-data access in this change.

## Credential partial-write checkpoint (2026-11-17)
Build19 adds fail-closed origin binding for reported new-key write failures. Isolated defaults/fake-writer tests cover mutation-then-throw, failure before mutation, successful binding, and same-origin failure. No real defaults/credentials or new storage format; existing configuration guard blocks unbound credentials before any client call. Focused Services and unsigned full candidate checks passed. No atomicity/crash guarantee claimed.

## Main-actor responsiveness and exact previews (build20)
BrowserCopySource.isForegroundProcess is lightweight process identity only. CapturedSelectionWindow.isCurrentOnWorker performs AX only on serial workers; isCurrentAsync awaits a dedicated serial worker. Copy transactions validate the window asynchronously before backup, again after backup and before clipboard clear, and before accepting fresh text. After each await, recheck cancellation/process/generation and clipboard version. Never yield between the final version comparison and clear, string read or restore. Shortcut posting still validates the window on its existing worker immediately before keydown and always sends keyup cleanup. Restore only the observed owned clipboard version, including cancellation paths. Return exact raw copied text, trim solely to detect empty content, and enforce the 20k limit against raw text. Missing AX trust prevents copy fallback entirely and shows the existing permission instructions; registered commands do not require an active pressure listener.

Window validation carries the shared capture permit and skips queued AX work if cancelled; check again after the issued IPC returns. Direct selection retains its1.5s read budget. Window capture and later identity validations are separate operations, each using an80ms AX messaging timeout per request; this is not an80ms total budget for the whole setup.

## Isolated technical-term vocabulary contract (build21)
The isolated-term classifier requires at least one letter and permits letters, marks and decimal digits. Internal hyphens/apostrophes must join letter-or-digit components. One or two terminal plus signs are allowed for terms such as C+ and C++; keep the complete selected term for literal provenance and exact normalized-entry comparison. Isolated3D, COVID-19, C++, .NET and C# require their own vocabulary entries; empty or unrelated vocabulary is invalid. Numeric-only input, punctuation-separated fragments such as happy/sad and Hello,world!, and full sentences can still have empty vocabulary. Do not add a dotted-identifier/math parser, morphology or dictionary rules; prompt/schema/transport stay unchanged.

## Cancellation status and listener disable (build21)
Controller invalidation snapshots pending AX/copy/analysis work before clearing it. Only that pending state changes the retained popup label to cancelled/retry and refreshes layout, without showing or ordering the popup. Settings saves, credential deletion and copy-option changes therefore cannot leave a cancelled request labelled loading. Completed/idle/preview labels remain intact; a retained capture permit alone does not mean work is pending. System/user tap disable cancels queued pressure handoffs before reporting status, using the existing source-time cutoff. It does not cancel an already started AX/AI request, change event masks or auto-reenable a user-disabled tap. Existing dismissal and deferred-trigger cancellation tests cover the state rules.

## Public-facing naming and generic selection errors
Use SelectEnglish as CFBundleName for the user-facing application menu; keep com.selectenglish.probe and the SelectEnglishProbe executable unchanged, so UserDefaults/runtime paths retain their existing identity. Empty-selection diagnostics refer to the target application rather than incorrectly assuming every failed source is a PDF. These copy/metadata corrections receive plist and whole-package validation, not cosmetic mirror tests.
