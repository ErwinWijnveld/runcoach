#!/usr/bin/env bash
#
# Wraps `flutter run` so a physical iPhone (or simulator) can always reach the
# Mac's `php artisan serve --host=0.0.0.0 --port=8001` without manually
# editing `lib/core/api/dio_client.dart` whenever the LAN IP changes.
#
# Also exports SDKROOT=iphonesimulator when targeting a simulator, which works
# around a Flutter native_assets bug where the `objective_c` build hook
# (transitive dep of `cupertino_native`) silently builds a device-only
# binary that the simulator can't dlopen, producing:
#   "Couldn't resolve native function 'DOBJC_initializeApi' …"
#   "Target native_assets required define SdkRoot but it was not provided"
# Setting SDKROOT explicitly tells the hook to compile arm64-apple-ios-simulator
# instead of arm64-apple-ios.
#
# Usage:
#   bash scripts/run-dev.sh                    # auto-detect IP, port=8001
#   PORT=8000 bash scripts/run-dev.sh          # override port
#   API_BASE_URL=https://... bash scripts/run-dev.sh   # override URL entirely
#   bash scripts/run-dev.sh -d <device-id>     # extra flags pass through
#
# Detection order: $API_BASE_URL → en0 (Wi-Fi) → en1 (Ethernet) → fail.

set -euo pipefail

cd "$(dirname "$0")/.."

PORT="${PORT:-8001}"

if [[ -n "${API_BASE_URL:-}" ]]; then
  url="$API_BASE_URL"
else
  ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(ipconfig getifaddr en1 2>/dev/null || true)"
  fi
  if [[ -z "$ip" ]]; then
    echo "Could not detect a LAN IP on en0 or en1." >&2
    echo "Set API_BASE_URL=http://<ip>:$PORT/api/v1 manually and retry." >&2
    exit 1
  fi
  url="http://${ip}:${PORT}/api/v1"
fi

# Detect whether `-d <id>` points at a simulator. Walk argv looking for `-d`
# followed by a UDID, then ask simctl whether that UDID is a known simulator.
# If yes, force SDKROOT=iphonesimulator so the objective_c build hook
# compiles for the simulator slice instead of the device slice.
target_device=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "-d" || "$prev" == "--device-id" ]]; then
    target_device="$arg"
    break
  fi
  prev="$arg"
done

if [[ -n "$target_device" ]]; then
  if command -v xcrun >/dev/null 2>&1 && \
     xcrun simctl list devices 2>/dev/null | grep -q "$target_device"; then
    export SDKROOT=iphonesimulator
    echo "[run-dev] Simulator target detected, SDKROOT=iphonesimulator"
  fi
fi

echo "[run-dev] API_BASE_URL = $url"
exec flutter run --dart-define=API_BASE_URL="$url" "$@"
