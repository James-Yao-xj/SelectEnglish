# Public beta readiness
## Goal
Prepare SelectEnglish for transparent public beta distribution, completing prior readiness findings where locally possible. The user explicitly requested completion of the listed work and maintains authorization for implementation, install, commit/push and releases. Do not invent successful external account/second-device evidence.
## Confirmed facts
0.9.3 arm64 ad-hoc app is installed. No valid local codesigning identities. Core offline suite exists. Native use was tested only on the user Mac. No LICENSE or CI. Local plaintext credentials are an approved product choice, outside repository; never read or log the real credential.
## Requirements
1. Reproducible arm64+x86_64 universal build, explicit minimum macOS13, formal Developer ID/hardened runtime/timestamp + notarytool/staple/Gatekeeper validation path. Explicit beta-only adhoc mode, never silently downgrade formal distribution. Do not create accounts or incur fees.
2. Native first-use help/menu entry explains privacy, macOS permissions/status/setup and dictionary conflict without changing popup workflow or auto-opening on every upgrade. Existing configured installs do not get intrusive first-use windows. No extra access or global key capture.
3. Chinese install/support/privacy/contribution/security/release checklist docs, honest prerequisites and limitations; LICENSE only after explicit user's MIT decision. Record unresolved license choice without blocking independent work.
4. Offline CI on Apple Silicon and Intel macOS runners with tests and universal candidate build validation, no secrets. CLI/CI success is not physical Force Click or clean-device launch evidence.
5. A reusable public-sample CET6 evaluation set/rubric with contextual/empty/single-word cases, structured validation via production AnalysisClient if an opt-in eval tool is supplied. Never read actual runtime key through tools. No fake accuracy claim.
6. Verify offline tests, compile/sign/universal metadata, native first-use UI with isolated preferences when feasible. Keep canonical installed working0.9.3 unchanged until a verified candidate and final delivery strategy is concrete. No unnecessary local TCC reset.
## Acceptance
Document precisely which gates passed and which require account credentials/another real Mac/human sample judgement. Publish source/pre-release artifacts under prior authorization if checks pass, never call an ad-hoc artifact formally notarized or general stable. Do not rewrite favorites or change production selection/AI model policy. Secret scan candidates before publish.
## External decisions/dependencies
Resolved: user has no Apple Developer account and asked to complete remaining preparation; user explicitly selected MIT. Formal notarization cannot pass without a usable identity/profile. Physical separate-machine testing cannot be simulated with CI.
