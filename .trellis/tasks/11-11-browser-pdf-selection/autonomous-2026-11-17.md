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
