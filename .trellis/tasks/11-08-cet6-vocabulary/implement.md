# Plan
- [x] Update bounded prompt policy and documentation.
- [x] Independent source check and existing regression/candidate compile.
- [x] Install signed0.9.3, verify native permission readiness and publish/record.

# Verification
All five offline test groups passed, full unsigned candidate compiled in independent review, final signed build passed checks and signature verification. Installed 0.9.3/build12 at the canonical path; old app retained in Trash. Main commit 0f9da7b pushed; public v0.9.3 release uploaded and remote ZIP digest matches local 3ed4a18480eb986b93af7a27855ef615ae81352019cbde3794ae7e17ac0fdf1f. Source scan found zero key patterns; actual runtime credential was never read by tools. No live AI quality sample yet. Native 0.9.3 process confirms Accessibility authorized, Input Monitoring allowed, listener created/enabled; 2,811 global gesture events observed with no listener disablements. No new real Force Click or AI response quality sample was requested. This is model-level filtering, not verified official lexicon membership.
