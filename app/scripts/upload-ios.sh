#!/usr/bin/env bash
# Upload the latest release IPA to App Store Connect (TestFlight).
#
# Prerequisite: build the IPA first
#   cd app && bash scripts/build-ios.sh
#
# One-time setup — App Store Connect API key:
#   1. https://appstoreconnect.apple.com → Users and Access → Integrations
#      → App Store Connect API → Generate API Key (Admin or Developer role)
#   2. Note the Key ID and Issuer ID shown on the page.
#   3. Download the .p8 file (ONLY OFFERED ONCE — save it).
#   4. Put it at:
#        mkdir -p ~/.appstoreconnect/private_keys
#        mv ~/Downloads/AuthKey_<KEY_ID>.p8 ~/.appstoreconnect/private_keys/
#      altool auto-discovers keys there.
#
# Usage:
#   cd app
#   export APP_STORE_CONNECT_API_KEY_ID=ABC123XYZ
#   export APP_STORE_CONNECT_ISSUER_ID=69a6de80-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   bash scripts/upload-ios.sh
#
# Or add the two exports to ~/.zshrc so you don't need to set them each time.

set -euo pipefail

: "${APP_STORE_CONNECT_API_KEY_ID:?Set APP_STORE_CONNECT_API_KEY_ID (see header of this script)}"
: "${APP_STORE_CONNECT_ISSUER_ID:?Set APP_STORE_CONNECT_ISSUER_ID (see header of this script)}"

IPA_PATH="${IPA_PATH:-build/ios/ipa/RunCoach.ipa}"

if [ ! -f "$IPA_PATH" ]; then
  echo "IPA not found at $IPA_PATH"
  echo "Run: bash scripts/build-ios.sh"
  exit 1
fi

echo "==> Validating $IPA_PATH"
xcrun altool --validate-app \
  --type ios \
  -f "$IPA_PATH" \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

echo "==> Uploading $IPA_PATH to App Store Connect"
xcrun altool --upload-app \
  --type ios \
  -f "$IPA_PATH" \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

echo "==> Upload complete."
echo "    Processing in App Store Connect usually takes 15-30 min."
echo "    Then: appstoreconnect.apple.com → RunCoach → TestFlight tab."
