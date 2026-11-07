# Reduce selection analysis latency
User reports long wait from selection to learning result; authorizes improving current native popup.
## Acceptance
- Official DeepSeek known current models use explicit non-thinking for this short learning task; unrelated custom endpoints receive no vendor-specific options.
- Keep vocabulary → sentence explanation → genuine fixed expressions and strict JSON validation/history compatibility.
- Keep useful concise content: no forced item counts; short usage and sentence explanations, one short example per fixed expression.
- Repeating the most recent exact selection with unchanged provider/model reuses a completed memory-only result. Retry always sends a fresh request; saving settings/deleting key clears reuse. No failed/canceled/stale results cached.
- Expose actual completed AI elapsed duration, and time to read selection in diagnostics, without text/key logs. Do not claim speedup without measured evidence.
- All current cancellation/generation and popup behavior remains intact. No permission expansion, automatic retries, or secret persistence.
