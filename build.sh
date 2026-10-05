#!/bin/bash
# Build T-Minus.app as a universal binary (Apple Silicon + Intel).
#   ./build.sh            build only
#   ./build.sh --install  copy to ~/Applications and launch
#   ./build.sh --dist     also produce build/T-Minus.zip for sharing
set -euo pipefail
cd "$(dirname "$0")"

APP="build/T-Minus.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" build/obj

for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 \
    -target "$arch-apple-macos14.0" \
    Sources/*.swift \
    -o "build/obj/TMinus-$arch"
done
lipo -create build/obj/TMinus-arm64 build/obj/TMinus-x86_64 -output "$APP/Contents/MacOS/TMinus"

cp Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "✓ built $APP ($(lipo -archs "$APP/Contents/MacOS/TMinus"))"

case "${1:-}" in
  --install)
    pkill -x TMinus 2>/dev/null || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/T-Minus.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/T-Minus.app
    echo "✓ installed to ~/Applications/T-Minus.app (look at your menu bar)"
    ;;
  --dist)
    rm -f build/T-Minus.zip
    ditto -c -k --keepParent "$APP" build/T-Minus.zip
    echo "✓ packaged build/T-Minus.zip"
    ;;
esac
