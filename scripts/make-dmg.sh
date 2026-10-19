#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf build
xcodebuild -project jWeather.xcodeproj -scheme jWeather -configuration Release \
  -derivedDataPath build/derived \
  CODE_SIGN_IDENTITY="${SIGN_IDENTITY:--}" \
  ${TEAM_ID:+DEVELOPMENT_TEAM="$TEAM_ID"} \
  build

STAGE="$(mktemp -d)"
cp -R build/derived/Build/Products/Release/jWeather.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname jWeather -srcfolder "$STAGE" -ov -format UDZO build/jWeather.dmg
rm -rf "$STAGE"

echo "Creato build/jWeather.dmg"