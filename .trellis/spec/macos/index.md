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
- Physical TextEdit Force Click plus full selection passed. Browser compatibility and a real configured provider remain QA items.

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
