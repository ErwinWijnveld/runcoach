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

# RevenueCat public iOS SDK key — bundled into the release binary. MUST be set
# in ~/.zshrc as REVENUECAT_PUBLIC_SDK_KEY=appl_xxx. Production builds without
# this key cannot serve the paywall; fail early rather than ship a broken IPA.
if [[ -z "${REVENUECAT_PUBLIC_SDK_KEY:-}" ]]; then
  echo "ERROR: REVENUECAT_PUBLIC_SDK_KEY is not set (check ~/.zshrc)." >&2
  echo "       Paywall + entitlement flow will not work without it." >&2
  exit 1
fi

echo "==> Building iOS release IPA"
echo "    API_BASE_URL = $API_BASE_URL"

flutter build ipa \
  --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=REVENUECAT_PUBLIC_SDK_KEY="$REVENUECAT_PUBLIC_SDK_KEY"

echo "==> Done. IPA: $(ls -1 build/ios/ipa/*.ipa 2>/dev/null || echo '(not found)')"
