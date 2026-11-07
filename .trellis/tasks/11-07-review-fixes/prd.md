# Fix full-review findings
User requests fixing all three P2 findings in review of bb865ce.
## Acceptance
- Single-word input must have a corresponding vocabulary entry after appropriate case/boundary-punctuation normalization; unrelated vocabulary rejected. Preserve original inflection, internal hyphens/apostrophes, valid simple sentences, legacy notebooks and legitimate empty arrays.
- Current Probe README explains actual automatically sent AI content, user-triggered local favorites, local credential file and real offline test/manual diagnostics. Remove or clearly label obsolete historic controls; link current root README.
- During asynchronous AX capture, subsequent click-away cancels/invalidate even when no popup has appeared. Late AX result neither shows popup nor starts HTTP. Ordinary idle clicks don't invalidate unrelated state. Ignore delayed delivery of initiating mouse-down; preserve one-trigger Force Click.
- Use the same production mouse-dismissal decision for local and global monitors and regression tests, including pre-trigger timestamp, hidden pending capture, visible inside/outside, idle hidden and superseded capture state.
- Preserve user settings, private local key/favorites and existing learning order, cache/retry, network/cancellation guards. No global keyboard monitor or broader permission mask.
- Build/review offline, then install final patch0.9.1 to canonical /Applications/SelectEnglish.app and update private GitHub/release under persistent user authorization. No secrets in source/artifacts.
