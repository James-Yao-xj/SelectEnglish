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
