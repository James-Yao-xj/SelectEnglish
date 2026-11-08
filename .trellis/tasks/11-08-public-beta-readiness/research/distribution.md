# Distribution research, 2026-11-08
Apple official distribution/notarization/packaging docs require Developer ID signing for formal independent distribution, hardened runtime and secure timestamp for notarization. Attach ticket to app before final ZIP; verify actual downloaded artifact on a different Gatekeeper-enabled Mac. No signing identities found locally.
https://developer.apple.com/macos/distribution/
https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
https://developer.apple.com/documentation/security/customizing-the-notarization-workflow
https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution
GitHub current official reference: macos-15 arm64, macos-15-intel x86_64. VM tests do not test Force Touch hardware.
https://docs.github.com/en/actions/reference/runners/github-hosted-runners
