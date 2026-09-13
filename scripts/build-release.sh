#!/bin/bash

set -euo pipefail

version="${1:?Usage: build-release.sh VERSION}"
build_number="${GITHUB_RUN_NUMBER:-1}"
build_root="${RUNNER_TEMP:-/tmp}/AnyIpsumRelease"
app_path="$build_root/Build/Products/Release/AnyIpsum.app"
dmg_path="dist/AnyIpsum-$version.dmg"
zip_path="dist/AnyIpsum-$version.zip"

rm -rf "$build_root" dist
mkdir -p dist

xcodebuild \
  -project AnyIpsum.xcodeproj \
  -scheme AnyIpsum \
  -configuration Release \
  -sdk macosx \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$build_root" \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  MARKETING_VERSION="$version" \
  CURRENT_PROJECT_VERSION="$build_number" \
  clean build

ditto -c -k --sequesterRsrc --keepParent \
  "$app_path" \
  "$zip_path"

hdiutil create \
  -volname AnyIpsum \
  -srcfolder "$app_path" \
  -ov \
  -format UDZO \
  "$dmg_path"

(
  cd dist
  shasum -a 256 "$(basename "$dmg_path")" "$(basename "$zip_path")" > SHA256SUMS
)
