# User-controlled local credentials
User explicitly reports repeated password prompts to access API and requests configuration once to suffice. Chosen behavior: remove Keychain dependency entirely; do not attempt to unlock, read, migrate or change ACLs on old Keychain data. This supersedes the original Keychain requirement for this user-approved revision.

Default file: `~/Library/Application Support/SelectEnglish/Private/api-key`, plaintext in an application-owned directory outside the repository. Directory0700 and file0600 restrict filesystem access to this user; this is not Keychain encryption. The user saves their key once in settings after upgrade, retains same-origin binding for a changed provider, and can delete saved local key. Source, build products and Git history must not contain the configured value. Secure UI fields stay empty on open and clear on close.

Temporary-file tests use fake values and injected paths only. Require missing/save/replace/reopen/delete, error propagation, and modes. Full application build must have no Security framework keychain symbols. Native QA should open settings with no key decrypt and exercise missing-key path without sending AI. Real-provider timing remains separate and may wait for the user's new local configuration.

Current prior system handoff resolved: the old app responded to CUA; main quit it through its menu and verified no SelectEnglish process remained. No SecurityAgent interaction or credential access occurred.

## Final v0.9 native acceptance
- Final signed v0.9 compiled; strict codesign/plist checks passed. No SecItem or SecKeychain undefined symbols in the application executable; no direct Keychain framework linking in build/test scripts.
- Opened native AI settings successfully with empty secure field; no Keychain prompt. User entered their own value and saved it; CUA observed the success label and cleared secure field. No tool accessed or printed its value.
- Actual private directory/file metadata confirmed0700/0600, without reading the file. Current app reports Accessibility allowed, Input Monitoring allowed, listener created/enabled.
- AX captured the same public80-character test sentence in0.01seconds. An explicit Retry produced real DeepSeek vocabulary → full sentence explanation → genuine fixed expressions, complete in1.9seconds total (AI1.9seconds). No password prompt appeared. This is one measured sample, not a guaranteed latency or comparative speedup percentage; v0.7 baseline was only an observation upper bound.
- Offline tests cover persistence across a new read, replace, deletion, modes, invalid UTF8/I/O, async cancel, service contracts and historical favorites. Native restart persistence was not separately exercised; no further signed rebuild was done after authorization/configuration.
