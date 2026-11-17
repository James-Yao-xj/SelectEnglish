#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# != 1 || ( "$1" != --beta && "$1" != --formal ) ]]; then
    echo "Usage: bash Probe/release.sh --beta | --formal" >&2
    exit 2
fi
mode="$1"
release_build="$PWD/.build/releases"
mkdir -p "$release_build/evidence"
# Keep one nonsecret receipt per attempt, including failures before an archive exists.
evidence_dir="$(mktemp -d "$release_build/evidence/run.XXXXXX")"
release_stage=""
phase=preflight
source_commit="$(git rev-parse HEAD)"
source_dirty=false
if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then source_dirty=true; fi
finish() {
    result=$?
    trap - EXIT
    if python3 - "$evidence_dir" "$mode" "$phase" "$result" <<'PYRECEIPT'
import datetime, json, pathlib, sys
folder, mode, phase, code = sys.argv[1:]
folder = pathlib.Path(folder)
snapshot = folder / 'build-input.json'
manifest = json.loads(snapshot.read_text()) if snapshot.exists() else {'inputSnapshotComplete': False}
manifest.update({'recordedAtUTC': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                 'mode': mode.removeprefix('--'), 'phase': phase, 'exitCode': int(code)})
archive_record = folder / 'artifact.json'
if archive_record.exists():
    manifest['artifact'] = json.loads(archive_record.read_text())
    manifest['verifiedArchitectures'] = ['arm64', 'x86_64']
receipt = folder / 'notarization.json'
if receipt.exists():
    manifest['notarization'] = json.loads(receipt.read_text())
(folder / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
if int(code) == 0 and archive_record.exists():
    target = folder.parent.parent / (manifest['artifact']['name'] + '.manifest.json')
    target.write_text(json.dumps(manifest, indent=2) + '\n')
PYRECEIPT
    then
        echo "Release evidence: $evidence_dir/manifest.json"
    else
        echo "Could not finish the release manifest; attempt evidence remains in $evidence_dir" >&2
    fi
    # Evidence errors must not hide the release exit status or prevent stage cleanup.
    if [[ -n "$release_stage" ]]; then
        rm -rf "$release_stage" || echo "Could not remove temporary release stage." >&2
    fi
    exit "$result"
}
trap finish EXIT
# Snapshot public build inputs before compilation or a long notarization wait.
cp Probe/Info.plist "$evidence_dir/Info.plist"
python3 - "$evidence_dir" "$source_commit" "$source_dirty" <<'PYINPUT'
import json, pathlib, plistlib, subprocess, sys
folder, commit, dirty = sys.argv[1:]
folder = pathlib.Path(folder)
info = plistlib.loads((folder / 'Info.plist').read_bytes())
def tool(*args):
    result = subprocess.run(args, text=True, capture_output=True)
    return result.stdout.strip() if result.returncode == 0 else {'probeExitCode': result.returncode}
manifest = {
    'inputSnapshotComplete': True, 'sourceCommit': commit, 'sourceDirtyAtStart': dirty == 'true',
    'version': info['CFBundleShortVersionString'], 'build': info['CFBundleVersion'],
    'deploymentTarget': info['LSMinimumSystemVersion'], 'targetArchitectures': ['arm64', 'x86_64'],
    'toolchain': {'swift': tool('swiftc', '--version'), 'macOS': tool('sw_vers', '-productVersion'),
                  'sdk': tool('xcrun', '--sdk', 'macosx', '--show-sdk-version')},
}
(folder / 'build-input.json').write_text(json.dumps(manifest, indent=2) + '\n')
PYINPUT
# Formal distribution never falls back to ad-hoc signing or skips notarization.
if [[ "$mode" == --formal ]]; then
    if [[ -z "${SIGNING_IDENTITY:-}" || -z "${NOTARY_PROFILE:-}" ]]; then
        echo "Formal release requires SIGNING_IDENTITY and NOTARY_PROFILE." >&2
        exit 2
    fi
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
phase=build
bash Probe/build.sh --unsigned
release_stage="$(mktemp -d "$release_build/stage.XXXXXX")"
release_app="$release_stage/SelectEnglish.app"
ditto .build/probe/SelectEnglish.app "$release_app"
cmp "$evidence_dir/Info.plist" "$release_app/Contents/Info.plist"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$release_app/Contents/Info.plist")"
if [[ "$mode" == --beta ]]; then
    codesign --force --sign - --identifier com.selectenglish.probe "$release_app"
    artifact_name="SelectEnglish-v${version}-beta.1.zip"
    echo "BETA ONLY: ad-hoc signature; not notarized or Gatekeeper-approved for general distribution."
else
    phase=signing
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$release_app"
    codesign --verify --strict --verbose=2 "$release_app"
    codesign -d --verbose=4 "$release_app" 2>&1 | grep -F 'Authority=Developer ID Application:' >/dev/null
    codesign -d --verbose=4 "$release_app" 2>&1 | grep 'flags=.*runtime' >/dev/null
    ditto -c -k --sequesterRsrc --keepParent "$release_app" "$release_stage/notary-upload.zip"
    phase=notarization
    notary_exit=0
    xcrun notarytool submit "$release_stage/notary-upload.zip" --keychain-profile "$NOTARY_PROFILE" \
        --wait --timeout 20m --output-format json > "$release_stage/notary-result.json" || notary_exit=$?
    # Preserve only Apple's public submission fields, never credentials or local paths.
    python3 - "$release_stage/notary-result.json" "$evidence_dir/notarization.json" <<'PYNOTARY'
import json, pathlib, sys
source, target = map(pathlib.Path, sys.argv[1:])
try:
    response = json.loads(source.read_text())
except json.JSONDecodeError:
    response = {}
receipt = {name: response[name] for name in ('id', 'status', 'createdDate') if name in response}
target.write_text(json.dumps(receipt, indent=2) + '\n')
PYNOTARY
    if [[ "$notary_exit" != 0 ]]; then exit "$notary_exit"; fi
    status="$(plutil -extract status raw -o - "$release_stage/notary-result.json")"
    if [[ "$status" != Accepted ]]; then echo "Notarization was not Accepted; no new release artifact produced." >&2; exit 1; fi
    xcrun stapler staple "$release_app"
    xcrun stapler validate "$release_app"
    spctl --assess --type execute --verbose=2 "$release_app"
    artifact_name="SelectEnglish-v${version}.zip"
fi
codesign --verify --strict --verbose=2 "$release_app"
xcrun lipo "$release_app/Contents/MacOS/SelectEnglishProbe" -verify_arch arm64 x86_64
phase=packaging
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
python3 - "$release_build/$artifact_name" "$evidence_dir/artifact.json" <<'PYARTIFACT'
import hashlib, json, pathlib, sys
archive, target = map(pathlib.Path, sys.argv[1:])
target.write_text(json.dumps({'name': archive.name, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest()}, indent=2) + '\n')
PYARTIFACT
phase=verified
echo "Verified artifact: $release_build/$artifact_name"
