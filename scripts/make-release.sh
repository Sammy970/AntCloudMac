#!/usr/bin/env bash
# Builds the public download for a GitHub release: dist/AntCloud-<version>-mac.zip.
# Ad-hoc signed (no personal certificate inside) and not notarized, so on first launch people use
# System Settings → Privacy & Security → Open Anyway. Moonlight is a separate install.
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION=$(sed -nE 's/.*static let appVersion = "([0-9.]+)".*/\1/p' Sources/Shared/Config.swift)
rm -rf dist
mkdir -p dist
OUT=dist scripts/build-app.sh --adhoc
ZIP="dist/AntCloud-$VERSION-mac.zip"
ditto -c -k --keepParent dist/AntCloud.app "$ZIP"
echo "Release build: $ZIP ($(du -h "$ZIP" | cut -f1)), version $VERSION"
codesign -dv dist/AntCloud.app 2>&1 | grep -E "^(Signature|Authority|TeamIdentifier)" || true
