#!/usr/bin/env bash
# Build a release IPA pointed at the production Laravel Cloud API.
#
# Usage:
#   cd app
#   bash scripts/build-ios.sh
#
# Output: build/ios/ipa/*.ipa — upload to App Store Connect via Transporter or
# Xcode Organizer, or run `xcrun altool --upload-app ...`.

set -euo pipefail

API_BASE_URL="${API_BASE_URL:-https://runcoach.free.laravel.cloud/api/v1}"

echo "==> Building iOS release IPA"
echo "    API_BASE_URL = $API_BASE_URL"

flutter build ipa \
  --release \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "==> Done. IPA: $(ls -1 build/ios/ipa/*.ipa 2>/dev/null || echo '(not found)')"
