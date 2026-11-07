# Install v0.9 acceptance

- Installed at `/Applications/SelectEnglish.app`, copied from verified signed0.9, identical executable and valid strict signature; no rebuild/resign.
- Old process quit via app menu. New process path is `/Applications/SelectEnglish.app/Contents/MacOS/SelectEnglishProbe`; only the installed copy is running.
- Native diagnostics confirmed Accessibility authorized, InputMonitoring allowed, tap created/enabled. Closed diagnostics, left menu-bar app running.
- No key/favorite contents read or modified; all runtime data remains outside app/repo.
- Obsolete copies moved to recoverable Trash; no permanent deletion.

Removed active locations:
- development/probe
- development/verified-v0.3
- development/verified-v0.4
- development/verified-v0.5
- development/verified-v0.6
- development/verified-v0.7
- development/selectenglish-candidate
- development/selectenglish-latency-candidate
- development/selectenglish-local-key-candidate
- exported/SelectEnglishProbe.app
- exported/SelectEnglishProbe-v0.3.zip
- exported/SelectEnglish-v0.5.zip
- exported/SelectEnglish-v0.6.zip
- exported/SelectEnglishProbe.zip

## GitHub release verification
Private repository confirmed via existing authenticated CLI (connector had no access). Published non-draft `v0.9`: https://github.com/James-Yao-xj/SelectEnglish/releases/tag/v0.9 . Assets: `SelectEnglish-v0.9.zip` (195529 bytes) and `SelectEnglish-v0.9.sha256` (89 bytes). GitHub asset digest matches local SHA256: `2b6b53338619b8205276d660d6a6731ac77963b9ba005d256977249c6f447664`. Archive root `SelectEnglish.app`, plist version0.9; no runtime api-key/notebook paths. Native app copy retains original verified signature and existing permissions.

Post-cleanup inventory of Applications/userApplications/Downloads/Desktop/projectbuild/outputs shows only installed application plus latest0.9zip in active locations. No extra API request was needed for this unchanged signed build. No application code changed or tests rerun; validation covered installation/signature/identity/permissions/package and release consistency.
