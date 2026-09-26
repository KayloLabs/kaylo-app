#!/bin/bash
# Builds the customer APK for a phone (mock data, arm64, which covers
# every recent Android phone).
#
# The map is OpenStreetMap unless a Google Maps key is present in
# android/local.properties (gitignored):
#   GOOGLE_MAPS_API_KEY=AIza...
# This script passes it to Flutter as the dart-define that switches the
# map engine to Google, and build.gradle.kts decodes the same define into
# the Android manifest, so the key is typed once and never committed.
#
#   apps/customer/tool/build_apk.sh
#   apps/customer/tool/build_apk.sh --split-debug-info=build/symbols   # extra flutter args pass through
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
  export JAVA_HOME
  JAVA_HOME=$(/usr/libexec/java_home)
fi

key=$(grep -E '^GOOGLE_MAPS_API_KEY=' android/local.properties 2>/dev/null \
  | head -1 | cut -d= -f2- | tr -d '[:space:]' || true)

defines=(--dart-define=USE_MOCK=true)
if [ -n "$key" ]; then
  defines+=("--dart-define=GOOGLE_MAPS_API_KEY=$key")
else
  echo "note: no GOOGLE_MAPS_API_KEY in android/local.properties, the map will use OpenStreetMap"
fi

flutter build apk --release --target-platform android-arm64 "${defines[@]}" "$@"
echo
echo "APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
