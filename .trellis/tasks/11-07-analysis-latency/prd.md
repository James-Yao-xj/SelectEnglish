# Reduce selection analysis latency
User reports long wait from selection to learning result; authorizes improving current native popup.
## Acceptance
- Official DeepSeek known current models use explicit non-thinking for this short learning task; unrelated custom endpoints receive no vendor-specific options.
- Keep vocabulary → sentence explanation → genuine fixed expressions and strict JSON validation/history compatibility.
- Keep useful concise content: no forced item counts; short usage and sentence explanations, one short example per fixed expression.
- Repeating the most recent exact selection with unchanged provider/model reuses a completed memory-only result. Retry always sends a fresh request; saving settings/deleting key clears reuse. No failed/canceled/stale results cached.
- Expose actual completed AI elapsed duration, and time to read selection in diagnostics, without text/key logs. Do not claim speedup without measured evidence.
- All current cancellation/generation and popup behavior remains intact. No permission expansion or automatic retries. Credential persistence follows the user-approved local-file revision below.

## User-authorized credential storage revision
User reports repeated Mac password prompts and explicitly wants user configuration to suffice. Replace Keychain with a local per-user application-support credential file, outside the Git repo, no Keychain reads/writes/migration. User enters API Key once after update. File plaintext, directory 0700/file 0600, atomic replacement. Never prefill/log/export the key; retain configured-origin binding and settings deletion. Do not change system security settings/ACLs, recover old secrets, or operate SecurityAgent. Verify missing/save/replace/delete/reopen/file modes with fake credentials in temporary directories. Preserve latency features and history compatibility.
