# Provider latency research
2026-11-07 official primary sources:
- https://api-docs.deepseek.com/guides/thinking_mode/
- https://api-docs.deepseek.com/api/create-chat-completion/
Official thinking guide says omitted controls default to thinking enabled and high effort. Top-level thinking: {type: disabled} explicitly requests non-thinking. This is a concrete avoidable source of latency in the current app, which sends neither thinking nor reasoning_effort. Actual total latency is not yet measured; network/provider queueing/output length can also matter. Do not apply DeepSeek extensions based only on a model prefix or similar hostname.

## Baseline observation
A real request was made through the running v0.7 app using the existing public TextEdit test sentence (80 characters). The popup was still loading immediately after Retry and was complete when next observed 17.8 seconds after click. This is an observation upper bound, not precise completion latency, and is not an A/B speedup measurement. No key was extracted and no user-private source was retransmitted.

## v0.8 native QA blocker
Accessibility and Input Monitoring were restored under prior explicit user permission; diagnostics confirmed allowed and tap enabled. The public TextEdit sample was captured. On Retry, CUA timed out. A process-stack sample showed the main thread waiting synchronously in KeyStore.read → SecItemCopyMatching → securityd decrypt, before the AI request. SecurityAgent was running; CUA explicitly refused access to this protected app. User handoff is required for this system confirmation. No new service latency is claimed from this wait, and no secret was read by a tool. An async keychain-read correction is in progress so this wait cannot freeze the popup or enable stale requests after cancel.

## Final code checkpoint
Async credential-read correction compiled and independently reviewed; all offline regressions passed with fake reader only. Two settings-only presence decrypt reads were removed, so opening settings no longer triggers key decryption merely for a status label. Final candidate contains all changes; the running signed process predates the async fix and is waiting on the protected OS confirmation. User was asked to dismiss that old prompt; final install and exact real-provider timing remain pending. No benchmark speedup is asserted.
