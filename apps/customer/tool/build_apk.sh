#!/bin/bash
# Builds the customer APK for a phone (arm64, which covers every recent
# Android phone).
#
#   apps/customer/tool/build_apk.sh           # demo build: sample data, no backend
#   apps/customer/tool/build_apk.sh --live    # live build: Supabase + Firebase
#   extra flutter args pass through, e.g. --split-debug-info=build/symbols
#
# Settings come from android/local.properties, which git ignores, so keys
# are typed once and never committed:
#   SUPABASE_URL=https://<project>.supabase.co        (needed for --live)
#   SUPABASE_ANON_KEY=sb_publishable_...              (needed for --live)
#   GOOGLE_SERVER_CLIENT_ID=<web client id>.apps.googleusercontent.com
#                                                     (optional, Google sign-in on Android)
#   GOOGLE_MAPS_API_KEY=AIza...                       (optional, else OpenStreetMap)
# build.gradle.kts decodes the Maps define into the Android manifest too.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
  export JAVA_HOME
  JAVA_HOME=$(/usr/libexec/java_home)
fi

prop() {
  grep -E "^$1=" android/local.properties 2>/dev/null \
    | head -1 | cut -d= -f2- | tr -d '[:space:]' || true
}

live=false
if [ "${1:-}" = "--live" ]; then
  live=true
  shift
fi

defines=()
if $live; then
  url=$(prop SUPABASE_URL)
  anon=$(prop SUPABASE_ANON_KEY)
  if [ -z "$url" ] || [ -z "$anon" ]; then
    echo "error: --live needs SUPABASE_URL and SUPABASE_ANON_KEY in android/local.properties" >&2
    exit 1
  fi
  defines+=("--dart-define=SUPABASE_URL=$url" "--dart-define=SUPABASE_ANON_KEY=$anon")
  client=$(prop GOOGLE_SERVER_CLIENT_ID)
  if [ -n "$client" ]; then
    defines+=("--dart-define=GOOGLE_SERVER_CLIENT_ID=$client")
  else
    echo "note: no GOOGLE_SERVER_CLIENT_ID, Google sign-in on Android may fail; phone sign-in is unaffected"
  fi
  echo "mode: LIVE (Supabase $url)"
else
  defines+=(--dart-define=USE_MOCK=true)
  echo "mode: demo (sample data, no backend)"
fi

maps=$(prop GOOGLE_MAPS_API_KEY)
if [ -n "$maps" ]; then
  defines+=("--dart-define=GOOGLE_MAPS_API_KEY=$maps")
else
  echo "note: no GOOGLE_MAPS_API_KEY, the map will use OpenStreetMap"
fi

flutter build apk --release --target-platform android-arm64 "${defines[@]}" "$@"
echo
echo "APK ($($live && echo live || echo demo)): $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
