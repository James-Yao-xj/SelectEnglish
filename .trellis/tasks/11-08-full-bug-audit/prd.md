# Full bug audit
User explicitly requests a new branch for bug fixes and multiple agents to inspect all code.
- Inspect every application source, experiment, build script and test; use current macOS spec and latest user-approved local plaintext credential/kraft appearance requirements.
- Independently confirm findings with concrete triggers, impact and isolated regressions; fix actionable correctness bugs, no speculative hardening or cosmetic refactor.
- Preserve installed application and live user configuration, credentials, favorites and permissions. Work on dedicated branch; do not merge to main, install or publish a release during audit.
- Tests only fake credentials/temp files/mock transport. Never access user key/file/notebook or real service. Candidate compile, never build.sh/sign.
- Record scope/coverage/findings/fixes/tests and remaining limitations; commit and push bug-fix branch under user's existing GitHub-update preference.
