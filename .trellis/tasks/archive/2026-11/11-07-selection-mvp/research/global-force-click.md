# Global Force Click: evidence and next experiment

Date: 2026-11-07. Research only; the verified v0.3 app was not edited or rebuilt in this research turn.

## Current facts
- Main-session physical/AX testing verified a 50-character TextEdit selection in authorized v0.3 after reset/regrant.
- The user screenshot had GLOBAL 0 and LOCAL 69 with visible stage 1. This does not establish global Force Click support.
- Existing local project `EnglishUp/docs/FORCE_TOUCH_FINDINGS.md` records earlier same-Mac global NSEvent pressure 0 and mouse pressure 1/0. Its later Chrome Lookup-window pair is a heuristic, not exact Force Click detection and not proven across apps. Repeating that same NSEvent monitor blindly has little value.

## Primary API evidence
1. Apple NSEvent global-monitor docs say it observes other-process events and cannot suppress their delivery. Its explicit supported-event list is labelled OS X 10.6; it excludes pressure but predates Force Touch. It is NOT evidence that all current versions categorically cannot deliver pressure.
   https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)
   The official `.md` version was fetched directly because the web reader could not render it.
2. Public SDK `CoreGraphics.framework/Headers/CGEventTypes.h` has no named Force Click/pressure event in CGEventType. Its kCGMouseEventPressure field is documented primarily as mouse pressure commonly set by tablet pens; values 1/0 do not encode the AppKit stage-2 contract.
3. Public AppKit NSEvent.h exposes gesture and pressure event types, conversion from CGEvent, and stage/pressure access. Read stage only on converted pressure events.
4. Apple CGEvent tapCreate supports passive listening, event masks and run-loop delivery; tap creation can fail or clear inaccessible bits. These APIs do not guarantee global stage-2 pressure delivery.
   https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsofinterest:callback:userinfo:)

## Concrete open-source evidence
Hammerspoon's own `extensions/eventtap/libeventtap_event.m`, function `eventtap_event_getTouchDetails`, checks the raw CG type against NSEventTypeGesture, converts with NSEvent eventWithCGEvent, and, if the converted type is NSEventTypePressure, exposes pressure/stage/stageTransition. This supports a different event-stream experiment: raw gesture can wrap converted pressure. Its eventtap source uses a session tap. This is implementation evidence, not a compatibility guarantee. The project also has private gesture synthesis code; do not copy that code or infer that every Hammerspoon feature is public API.
- https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/eventtap/libeventtap_event.m
- https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/eventtap/libeventtap.m

## Recommended bounded experiment
Preserve the working authorized v0.3 bundle before any rebuild. Add an explicitly started passive CGEvent session tap, common-mode run loop, public NSEvent(cgEvent:) conversion, and in-memory numeric metadata only.

Mask the publicly named AppKit gesture and pressure raw values plus mouse down/up/drag; do not use maskAll, keyboard fields, or keyboard logging. Key point: pressure mask alone may miss raw gesture wrappers. First inspect raw type and converted NSEvent type. Read stage/pressure only when converted type is pressure. Count stage-2 transitions once per physical gesture; record actual target app at receipt. Keep callbacks small and perform AX work outside the tap callback. Show tap creation failure, disabled state, total non-keyboard events, gesture wrappers and converted pressure separately so silence is diagnosable.

Test real Force Click over TextEdit and a browser, compare ordinary click and drag, verify one trigger and full selection. The working v0.3 manual AX path remains separate. Passive tap cannot suppress system Lookup; stage-2 may arrive after selection changes.

## Limits and alternatives
No result from this experiment exists yet. Receiving mouse events but zero converted pressure would narrow the limitation; it would not prove every public mechanism impossible. Missing tap installation is a permissions/setup result, not hardware evidence. Reading raw private event fields, dynamically loading MultitouchSupport, or relying on undocumented IOHID Force Touch fields would change architecture/maintenance assumptions and requires a separate evidence-based design decision. Do not silently adopt those or replace Force Click with Lookup-window heuristics or keyboard shortcuts.

## Experiment implementation readiness
`Probe/Experiments/main.swift` compiles as a standalone helper; the existing v0.3 app was not rebuilt. A two-second passive session-tap setup run returned TAP_READY with selective mask [1,2,6,29,34], then exited normally. No physical input was supplied; all counters were zero. This only verifies setup, not global pressure delivery. The main session owns the live baseline and physical test. Hammerspoon source location: `eventtap_event_getTouchDetails` (line numbers drift on master; fetched current raw source checks raw gesture then converted pressure).

## Live breakthrough
User performed Force Click while the passive helper was running. Observed cumulative counters: mouse 19, rawGesture 1885, rawPressure 0, convertedPressure 192, stages [0:7,1:114,2:71], stage2Triggers 2, disabled 0. Thus raw gesture conversion delivers real stage 2 on this Mac; pressure bit 34 alone would have missed these events. Ordinary baseline produced stages 0/1 and no trigger. Next: integrate adapter and verify actual selection at trigger time; trigger success alone does not prove full selection retention or browser compatibility.

## Physical breakthrough and v0.4 integration
The main session reports actual user Force Click produced convertedPressure=192, stage2 events=71, stage2Triggers=2 in the standalone passive session tap. This verifies the raw-gesture conversion route on this Mac. It does not verify integrated selection retention. Main also observed TextEdit no longer exposed its prior 50-character selection after force click; normal mouse-down or Lookup may change selection.
v0.4 integrates the same selective passive stream; snapshots front app on stage2, sends AX to serial worker, rejects exited/reused PID, uses latest-result generation guards, and never activates itself on capture. Build and 4 gate checks/signature/plist passed. v0.3 preserved before rebuild; no launch or privacy reset performed by implementer. Integrated physical trigger plus text result is pending.

## Integrated v0.4 live result
After user Force Click in TextEdit, main observed v0.4 UI: AX trusted, passive tap installed/enabled, global rawGesture1954, converted pressure189, stage2 events34, deduplicated trigger1. Target TextEdit, AXTextArea, successful full50-character selection, exact scratch sentence. Thus genuine cross-app Force Click → AX full selection is verified on TextEdit. Browser remains pending. The previous inference that normal click necessarily loses the selection was not established; actual stage2 capture succeeded.

## Final v0.5 browser + UI evidence
User performed Force Click in Chrome. Main CUA observed source Google Chrome,40 characters captured in result window; AI configuration validation displayed missing endpoint/model. No real AI request sent. Settings layout/empty-field validation, empty favorites and authorized/enabled diagnostics were observed. Final AI settings window left open. User-configured provider credentials are still absent; production AI quality/connectivity remains unverified.
