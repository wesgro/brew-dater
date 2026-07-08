#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="BrewMenu"
BUILD_DIR=".build/apple/Products/Release"
APP_BUNDLE=".build/${APP_NAME}.app"

echo "Building release binary..."
swift build -c release --product BrewMenuApp

BIN_PATH=$(swift build -c release --product BrewMenuApp --show-bin-path)

echo "Assembling ${APP_BUNDLE}..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH/BrewMenuApp" "$APP_BUNDLE/Contents/MacOS/BrewMenuApp"
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"

echo "Ad-hoc code signing..."
codesign --force --deep -s - "$APP_BUNDLE"

echo "Done: $APP_BUNDLE"
echo
echo "To install: cp -R \"$APP_BUNDLE\" /Applications/"
