#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# != 1 || ( "$1" != --beta && "$1" != --formal ) ]]; then
    echo "Usage: bash Probe/release.sh --beta | --formal" >&2
    exit 2
fi
mode="$1"
# Formal distribution never falls back to ad-hoc signing or skips notarization.
if [[ "$mode" == --formal ]]; then
    : "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to a Developer ID Application certificate name}"
    : "${NOTARY_PROFILE:?Set NOTARY_PROFILE to an existing notarytool keychain profile}"
    if [[ "$SIGNING_IDENTITY" != 'Developer ID Application:'* ]]; then
        echo "Formal release requires a Developer ID Application identity." >&2; exit 2
    fi
    if ! security find-identity -v -p codesigning | grep -F -- "\"$SIGNING_IDENTITY\"" >/dev/null; then
        echo "Requested Developer ID Application identity is not available." >&2; exit 2
    fi
fi
for resource in LICENSE PRIVACY.md; do
    if [[ ! -f "$resource" ]]; then echo "Missing release resource: $resource" >&2; exit 2; fi
done
bash Probe/build.sh --unsigned
release_build="$PWD/.build/releases"
mkdir -p "$release_build"
release_stage="$(mktemp -d "$release_build/stage.XXXXXX")"
trap 'rm -rf "$release_stage"' EXIT
release_app="$release_stage/SelectEnglish.app"
ditto .build/probe/SelectEnglish.app "$release_app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$release_app/Contents/Info.plist")"
if [[ "$mode" == --beta ]]; then
    codesign --force --sign - --identifier com.selectenglish.probe "$release_app"
    artifact_name="SelectEnglish-v${version}-beta.1.zip"
    echo "BETA ONLY: ad-hoc signature; not notarized or Gatekeeper-approved for general distribution."
else
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$release_app"
    codesign --verify --strict --verbose=2 "$release_app"
    codesign -d --verbose=4 "$release_app" 2>&1 | grep -F 'Authority=Developer ID Application:' >/dev/null
    codesign -d --verbose=4 "$release_app" 2>&1 | grep 'flags=.*runtime' >/dev/null
    ditto -c -k --sequesterRsrc --keepParent "$release_app" "$release_stage/notary-upload.zip"
    xcrun notarytool submit "$release_stage/notary-upload.zip" --keychain-profile "$NOTARY_PROFILE" \
        --wait --timeout 20m --output-format json > "$release_stage/notary-result.json"
    status="$(plutil -extract status raw -o - "$release_stage/notary-result.json")"
    if [[ "$status" != Accepted ]]; then echo "Notarization was not Accepted; no release artifact produced." >&2; exit 1; fi
    xcrun stapler staple "$release_app"
    xcrun stapler validate "$release_app"
    spctl --assess --type execute --verbose=2 "$release_app"
    artifact_name="SelectEnglish-v${version}.zip"
fi
codesign --verify --strict --verbose=2 "$release_app"
xcrun lipo "$release_app/Contents/MacOS/SelectEnglishProbe" -verify_arch arm64 x86_64
# Package only after stapling in formal mode, and validate the actual extracted artifact.
archive="$release_stage/$artifact_name"
ditto -c -k --sequesterRsrc --keepParent "$release_app" "$archive"
mkdir "$release_stage/extracted"
ditto -x -k "$archive" "$release_stage/extracted"
extracted_app="$release_stage/extracted/SelectEnglish.app"
codesign --verify --strict --verbose=2 "$extracted_app"
xcrun lipo "$extracted_app/Contents/MacOS/SelectEnglishProbe" -verify_arch arm64 x86_64
plutil -lint "$extracted_app/Contents/Info.plist"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$extracted_app/Contents/Info.plist")" == 13.0 ]]
for arch in arm64 x86_64; do
    xcrun vtool -arch "$arch" -show-build "$extracted_app/Contents/MacOS/SelectEnglishProbe" | awk '$1 == "minos" { found=1; if ($2 != "13.0") exit 1 } END { if (!found) exit 1 }'
done
cmp "$release_app/Contents/Info.plist" "$extracted_app/Contents/Info.plist"
for resource in LICENSE PRIVACY.md; do cmp "$resource" "$extracted_app/Contents/Resources/$resource"; done
if [[ "$mode" == --formal ]]; then
    xcrun stapler validate "$extracted_app"
    spctl --assess --type execute --verbose=2 "$extracted_app"
fi
(cd "$release_stage" && shasum -a 256 "$artifact_name" > "$artifact_name.sha256" && shasum -a 256 -c "$artifact_name.sha256")
mv "$archive" "$archive.sha256" "$release_build/"
echo "Verified artifact: $release_build/$artifact_name"
