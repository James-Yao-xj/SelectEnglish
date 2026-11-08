# Plan
- [ ] Implement universal build/distribution scripts and CI; verify missing-credential behavior and beta archive.
- [ ] Implement native first-use guidance and bundled guidance; preserve existing installs.
- [ ] Write public docs, privacy/data flow, install troubleshooting, external QA and CET6 evaluation cases; resolve license.
- [ ] Independent full-scope review, offline suite, universal compile/sign metadata, native visual QA where possible.
- [ ] Commit/push and publish an explicitly labeled beta candidate only; record remaining external gates and installed state accurately.
# Rollback
Do not replace installed0.9.3 until validated; retain old app in Trash if installing. No runtime credential access/migration. Failed notarization must not create a public-ready package. Never weaken Gatekeeper/TCC to make release QA pass.
