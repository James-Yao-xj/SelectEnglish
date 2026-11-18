# Release evidence contract

## Reproducible release evidence
1. **Scope / trigger:** preserve diagnostic release evidence when staging is cleaned, including formal preflight/notarization failures.
2. **Signatures:** `Probe/release.sh --beta|--formal` writes `.build/releases/evidence/run.*/manifest.json`; a verified archive also gets `ZIP.manifest.json`.
3. **Contracts:** capture source commit/dirty flag, bundle version/build, deployment target, SDK/compiler/OS versions before build. Successful evidence contains archive SHA256 and verified architecture slices. Keep only nonsecret notarization id/status/date; no credential/profile/environment dump. Formal failures never become beta artifacts.
4. **Validation / errors:** missing formal inputs exits nonzero and retains preflight evidence. Receipt-writer failure turns an otherwise successful exit into nonzero; preserve an existing nonzero code and always clean staging. Final artifact success is reported only after the required manifest is written. Never label target architectures as verified on a failed build.
5. **Cases:** Good: verified ZIP and receipt can be tied to source commit. Base: missing signing identity produces failure evidence only. Bad: cleanup deletes the only notarization submission id or a failed attempt points at an old ZIP as its output.
6. **Required tests:** shell syntax; real missing-input exit/status/manifest; actual finish-handler success, receipt-write failure 0→1 and earlier failure 7→7 with cleanup; beta packaging/extraction/resources/signature/universal checks. CI preserves nonsecret evidence separately per runner; formal notarization still needs an actual developer account.
7. **Wrong vs correct:** keep sanitized receipts outside temporary stage. Do not upload raw stage, user files, actual credentials, or environment variables as CI artifacts.

