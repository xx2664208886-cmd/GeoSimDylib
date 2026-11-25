#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${ROOT_DIR}/build"
OUT_FILE="${OUT_DIR}/GeoSimHook.dylib"

mkdir -p "${OUT_DIR}"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
CC="$(xcrun --sdk iphoneos --find clang)"

echo "Using SDK: ${SDK_PATH}"
echo "Building GeoSimHook.dylib (arm64, iOS 14.0+)..."

"${CC}" \
  -arch arm64 \
  -isysroot "${SDK_PATH}" \
  -miphoneos-version-min=14.0 \
  -fobjc-arc \
  -dynamiclib \
  -O2 \
  -Wall -Wextra -Wno-unused-parameter \
  -install_name "@rpath/GeoSimHook.dylib" \
  -framework Foundation \
  -framework UIKit \
  -framework CoreLocation \
  -framework MapKit \
  -framework CoreGraphics \
  -Wl,-dead_strip \
  -o "${OUT_FILE}" \
  "${ROOT_DIR}/src/GeoSimCoords.m" \
  "${ROOT_DIR}/src/GeoSimEngine.m" \
  "${ROOT_DIR}/src/GeoSimLocationHook.m" \
  "${ROOT_DIR}/src/GeoSimOverlay.m" \
  "${ROOT_DIR}/src/GeoSimViewController.m"

if command -v ldid >/dev/null 2>&1; then
  ldid -S "${OUT_FILE}"
else
  codesign --force --sign - "${OUT_FILE}"
fi

echo "Done: ${OUT_FILE}"
file "${OUT_FILE}"
otool -L "${OUT_FILE}"
