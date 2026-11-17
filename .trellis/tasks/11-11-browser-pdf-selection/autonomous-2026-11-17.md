# Autonomous improvement window

The user explicitly authorized ten hours of autonomous work without questions.

- Start: 2026-11-17 13:22:20 UTC (21:22:20 Asia/Shanghai).
- Deadline: 2026-11-17 23:22:20 UTC (07:22:20 next day Asia/Shanghai).
- Baseline: clean `fix/browser-pdf-selection` at `8e1cd5f`.
- Keep the goal active until the deadline. Preserve the fix branch; do not merge main or publish a stable release without verified readiness.
- Never inspect actual API credentials, record private source/clipboard text, or bypass lock-screen/authentication. Defer human-only steps and continue independent work without questions.
- This user authorization supersedes earlier task notes that requested additional routine planning/commit confirmation. It does not authorize broader system permissions or access to private data.

## Priorities

1. Verify browser PDF behavior using a public fixture and a selection-preserving command. Do not repeat blind rebuild/permission cycles.
2. Keep Force Click and add an explicit menu command and registered Control-Option-Command-T shortcut. Do not monitor ordinary keyboard events or pre-copy ordinary selections.
3. Fix reproduced cancellation and response-provenance errors. Test production state transitions rather than mirror implementation details.
4. Improve truthful user documentation and release evidence. Keep native hardware, algorithm tests, package validation, and public release status distinct.

## Decisions

- PDF mouse-down can clear the selection before pressure stage 2. A menu/registered-hotkey alternative avoids that destructive mouse-down without suppressing browser input.
- General pasteboard change counts cannot identify the first writer. Copied fallback text must be previewed and explicitly approved with Analyze before HTTP; direct authoritative AX selection may still analyze automatically.
- Preserve original trigger timestamps and cancel queued trigger handoffs on later input, explicit cancellation, and listener stop. Keep existing input masks.
- Bind sentence vocabulary to literal original source forms, without claiming deterministic CET-6 classification. Historical favorites remain unchanged.
- Retain sanitized release manifests and notarization receipts, including failed attempts. Do not include credentials, environment dumps, or private document URLs.

## Execution log

- 13:22 UTC: started goal and delegated design, correctness, and documentation audits.
- 13:30 UTC: approved menu/hotkey, clipboard preview, timestamp fix, and release-evidence changes. Root owns native QA; agents own disjoint source/docs scopes.
- 13:32 UTC: native Chrome testing was interrupted by foreground changes and a CUA timeout. No selection or translation success claimed. Deferred native QA until candidate is frozen; continued source review.

- 13:50 UTC: committed and pushed the first reviewed batch through4f6bf85. Clean-source build17 passed11 groups and full beta verification, SHA2563431c6e30ca925a627ccdbe94b4b3849df4b852f74dd38892ce6af425dc17995. Both CI runners passed run44096819648; nonsecret evidence artifacts verified present.
- 14:02 UTC: opened draft PR1 through existing CLI authorization after the connector returned403. No merge, stable release, or installer replacement. Added direct delegate-policy regression and measured source-validation CPU; isolated hoist saves~5.55ms near20k characters, not an explanation for seconds of network delay.
- 14:05 UTC: native inventory still timed out after a CUA kernel reset. Continue independent work; no lock-screen bypass or permission changes. Build18 cancels obsolete serial AX jobs with a shared permit; deterministic queue tests and independent review passed. The next full package will supersede the build17 local candidate.

- 14:07 UTC: clean-source build18 at93b6c95 passed12 groups and package verification, SHA25682d9b63e594351ec12bae81ca54c6b15156522613d8530002f131de58dc4ed9b. PR CI44099695740 passed. No app installation; native inventory still timed out at14:20.
- First-hour follow-up: actual ThreadSanitizer run on the production permit/serial-cancellation scenario passed without diagnostics. Reproduced and fixed required-manifest failure reporting (0→1, original7 retained), and reported credential-write partial failures (clear origin before mutation, bind only after success). Focused checks and independent review passed; build19 joint package remains next. These changes do not claim filesystem/UserDefaults crash atomicity.

- 14:27 UTC: direct app targeting worked despite inventory/browser-extension timeouts. Quit old16 via app menu, verified process exit, installed signed packaged build19 without resigning; old16 moved to recoverable Trash, runtime data untouched. Current19 registered shortcut successfully but reports AX/input untrusted; SystemSettings old AX entry is on. No authentication was attempted or bypassed. Freeze20 before one normal permission refresh attempt.
- 14:36 UTC: native Chrome in a separate window loaded public W3C dummy.pdf; triple-click selected exact Dummy PDF file without pressure. This is preparation/selection preservation evidence only, not app capture/translation evidence. Extension browser API remains unreliable; prefer targeted native app control.
- 14:44 UTC: complete branch code-review axes finished. Standards found main-thread window AX IPC and whitespace trimming; build20 fixes both with async worker validation and exact preview preservation. Independent follow-up closed both findings; Spec found no actionable code defect but native acceptance remains incomplete. See review-2026-11-17.md. Current20 source requires clean final packaging before installation.

- 15:34 UTC: second-hour checkpoint. Build20 clean08affaf packaged/installed, SHA256c48c33dd1b3aafcbe6b4b2e8a449f6f2fdf9a34141d7c62b08da4a99122cb775; CI44107095299 passed. Normal permission refresh requested OS login authentication; canceled without credentials or questions, old toggle unchanged. Manual Chrome read shows empty source/result and authorization instruction. Hotkey registration is confirmed, synthetic chord delivery is not. Native positive PDF/physical gates remain open.
- Enabled public-repository secret_scanning and secret_scanning_push_protection using existing administrative CLI authorization; response confirmed both enabled. No alerts or secret values were read. Official docs establish free public-repository availability; not all custom credentials are detectable.
- Closed only project-owned translation/diagnostic windows. Started nonsecret5-minute CPU/RSS/version observation through23:22:20UTC: /private/tmp/selectenglish-idle-observation-3r5o3l9v/samples.jsonl (session49677). Initial build20 PID82066,0.0%CPU,48768KiBRSS. This observes the permission-inactive background app, not active AX/AI throughput or controlled battery use.
- Build21 source adds proven isolated-technical-term validation, centralized pending cancellation labels, and deferred-trigger cancellation on user-input tap disable. Focused checks/source reviews complete; final clean package is next. Explicit Cancel feedback was retained for previews and completed results.

- 15:48 UTC: build21 follow-up reviews passed. Technical-term gap closed; centralized cancel labels preserve completed/previews and explicit Cancel feedback; user-input disable cancels queued tokens only. User-facing CFBundleName becomes SelectEnglish, preserving bundleID/executable and runtime paths; generic selection error no longer assumes every app is PDF. Next clean package and draft-release preparation do not imply native completion or public stable publishing.
