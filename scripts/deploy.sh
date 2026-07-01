#!/usr/bin/env bash
#
# Build HomeGym (Release, ad-hoc signed) and install it to /Applications.
# Ad-hoc signing is used because there's no Apple ID in Xcode's Accounts here;
# the app still runs locally and Calendar/Notification permissions work by bundle ID.
#
# Usage: ./scripts/deploy.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "▸ Building HomeGym (Release, ad-hoc)…"
xcodebuild -scheme HomeGym -configuration Release -destination 'platform=macOS' \
  -derivedDataPath ./build build \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" ENABLE_HARDENED_RUNTIME=NO \
  >/dev/null

APP="build/Build/Products/Release/HomeGym.app"
[ -d "$APP" ] || { echo "✗ Build product not found at $APP"; exit 1; }

echo "▸ Quitting any running instance…"
osascript -e 'tell application "HomeGym" to quit' 2>/dev/null || true
pkill -x HomeGym 2>/dev/null || true
sleep 1

echo "▸ Installing to /Applications…"
rm -rf /Applications/HomeGym.app
cp -R "$APP" /Applications/HomeGym.app
xattr -dr com.apple.quarantine /Applications/HomeGym.app 2>/dev/null || true

echo "▸ Launching…"
open /Applications/HomeGym.app

echo "✓ HomeGym updated in /Applications"
