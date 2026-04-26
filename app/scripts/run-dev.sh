#!/usr/bin/env bash
#
# Wraps `flutter run` so a physical iPhone (or simulator) can always reach the
# Mac's `php artisan serve --host=0.0.0.0 --port=8001` without manually
# editing `lib/core/api/dio_client.dart` whenever the LAN IP changes.
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

echo "[run-dev] API_BASE_URL = $url"
exec flutter run --dart-define=API_BASE_URL="$url" "$@"
