# Plan
- [x] Implement universal build/distribution scripts and CI; verify missing-credential behavior and beta archive.
- [x] Implement native first-use guidance and bundled guidance; preserve existing installs.
- [x] Write public docs, privacy/data flow, install troubleshooting, external QA and CET6 evaluation cases; resolve license.
- [x] Independent full-scope review, offline suite, universal compile/sign metadata, native visual QA where possible.
- [x] Commit/push and publish an explicitly labeled beta candidate only; record remaining external gates and installed state accurately.
# Rollback
Do not replace installed0.9.3 until validated; retain old app in Trash if installing. No runtime credential access/migration. Failed notarization must not create a public-ready package. Never weaken Gatekeeper/TCC to make release QA pass.

# Results
User has no Apple Developer account and explicitly deferred it; user chose MIT. Completed rest: fresh native first-use/privacy help with quiet existing-install policy, universal0.10.0/build13 min13, explicit formal-vs-beta pipeline, no-secrets dual-host CI, MIT/privacy/install/security/contribution/release docs,10case evaluation corpus and4 actualproductionCET6 UI samples. Independent review and six offline groups passed. Both GitHub hosts passed in run42450081428 (source5a37379). Native isolated firstlaunchhelp screenshot passed; no QA permissions granted and QA copy moved to Trash. Working installed0.9.3 remains authorized and untouched, beta candidate shipped separately. ArtifactSHA40a883cc6c738846e19be68774dd2fc8f8fde94f7b6c6bc436c8963aae67e9e5. No actual runtimekey read or uploaded. Public v0.10.0-beta.1 prerelease verified uploaded; remote ZIP digest equals local SHA. Source/docs committed and pushed.
# Deferred external gates
No Developer ID/notarization executed; no real clean second-Mac, minimum-macOS13 run or Intel Force Touch test. These are explicit pending gates in docs, not claims of completion. Full10case repeated evaluation/independent language scoring also pending; actual4case observations documented honestly.
