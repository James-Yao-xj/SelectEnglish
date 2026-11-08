# Full application audit — 2026-11-08
Branch: fix/full-audit-2026-11-08; base e474855 (main v0.9.2).

## Parallel coverage
1. Native agent: main capture/lifecycle/async guards, ForceClickMonitor/GestureGate, SelectionReader, ResultPopup/PopupDismissalState/PopupGeometry, Experiments and associated tests.
2. API agent: complete Analysis.swift HTTP/config/schema/single-word/provider/redirect/error handling, caller cache/settings/generation guards and Services tests.
3. Storage agent: Storage.swift key/favorite persistence, settings/notebook callbacks, tests/build scripts, plist, README/.gitignore.
Main independently inspected cross-layer favorite identity and ran full offline baseline; all baseline groups passed. Generated Trellis scaffolding is workflow infrastructure, not rewritten as app code.

## Confirmed findings
### P1: stale favorite picker can delete the wrong saved record
Open notebook displaying A at index0; save C through popup. NotebookStore prepends C, but picker still displays A. Delete callback resolves entries[index0] and deletes C, not A. Isolated compiled fake-file proof: Displayed A; deleted C; disk [A]. Fixed: production NotebookMenuSelection binds/resolves UUID; main refreshes after save and preserves selection by UUID. Production-menu fake-file regression verifies deleting A after prepend keeps C across reopen.

### P2: dismissal follows current pointer instead of recorded mouse event
Queued outside click delivered after pointer returns over popup is incorrectly classified inside; inverse misclassifies inside click. Current ResultPopup uses NSEvent.mouseLocation; fix must use the delivered event point converted to screen. Apple references: https://developer.apple.com/documentation/appkit/nsevent/locationinwindow and https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/EventObjectsTypes/EventObjectsTypes.html . Fixed: shared PopupMouseEvent converts recorded event location to screen; production caller containment uses it. Safe synthetic nil-window event regressions cover inside/outside and negative monitor coordinates without posted events.

## Limits
No live hardware/AX/UI interaction, provider request, secret/preferences/notebook access, app installation, signing, permission changes or main merge in this audit. API slice found no additional confirmed correctness bug; that is not proof that no undiscovered issue exists. Existing deterministic timing/generation fixes were reviewed, not reported again as new findings.

## Final independent verification
A fourth, independent check agent reviewed the entire change and found no remaining actionable issue. All five offline groups passed: gesture gate; services/schema/private fake files/history plus actual NSMenuItem stale-A/prepend-C/delete/reopen; popup geometry; dismissal timing/generation; synthetic recorded mouse events including negative screen coordinates. Whole application compiled unsigned from all current sources. No source version bump, main merge, installed-app update, permissions change or real service call.

New paths: NotebookMenuSelection.swift (production UUID menu binding/resolution), PopupMouseEvent.swift (recorded event screen point), Tests/MouseEvent/main.swift. main.swift refreshes notebook immediately after save and preserves existing UUID. ResultPopup uses recorded event point for containment. Storage persistence format unchanged.

Runtime limits: local-window convertPoint and NSPopUpButton refresh are source-reviewed, not exercised with live windows. Synthetic mouse objects are never posted. The audit does not assert bug-free software or re-prove physical Force Click support.
