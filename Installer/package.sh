#!/bin/bash
# Assembles Mouse Studio into two .app bundles and a .dmg installer.
# Usage: Installer/package.sh <version>
# Must be run from the repository root on macOS.
set -euo pipefail

VERSION="${1:-0.0.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Building release binaries…"
swift build -c release
BIN="$(swift build -c release --show-bin-path)"

DIST="$ROOT/dist"
DMGROOT="$DIST/dmgroot"
rm -rf "$DIST"
mkdir -p "$DMGROOT"

# ---- Helper: assemble a .app bundle -------------------------------------
# make_app <AppName> <executable-name> <bundle-id> <lsuielement true|false>
make_app() {
  local app_name="$1" exe="$2" bundle_id="$3" ui_element="$4"
  local app="$DMGROOT/${app_name}.app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$BIN/$exe" "$app/Contents/MacOS/$exe"

  local ui_key=""
  if [ "$ui_element" = "true" ]; then
    ui_key="    <key>LSUIElement</key><true/>"
  fi

  cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${app_name}</string>
    <key>CFBundleDisplayName</key><string>${app_name}</string>
    <key>CFBundleIdentifier</key><string>${bundle_id}</string>
    <key>CFBundleExecutable</key><string>${exe}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
${ui_key}
</dict>
</plist>
PLIST
  echo "APPLnone" > "$app/Contents/PkgInfo"
  echo "    assembled ${app_name}.app"
}

echo "==> Assembling app bundles…"
make_app "MouseStudio" "mousestudio-gui" "com.mousestudio.gui" "false"
make_app "MouseStudioService" "mousestudio-service" "com.mousestudio.service" "true"

# Ship device profiles as resources for the service.
mkdir -p "$DMGROOT/MouseStudioService.app/Contents/Resources/DeviceProfiles"
cp "$ROOT"/DeviceProfiles/*.json "$DMGROOT/MouseStudioService.app/Contents/Resources/DeviceProfiles/"

echo "==> Ad-hoc code signing…"
codesign --force --deep --sign - "$DMGROOT/MouseStudioService.app" || echo "  (codesign skipped/failed; ad-hoc)"
codesign --force --deep --sign - "$DMGROOT/MouseStudio.app" || echo "  (codesign skipped/failed; ad-hoc)"

# Installer helpers alongside the apps in the disk image.
cp "$ROOT/Installer/install.sh" "$DMGROOT/Install.command"
cp "$ROOT/Installer/uninstall.sh" "$DMGROOT/Uninstall.command"
cp "$ROOT/Installer/com.mousestudio.service.plist" "$DMGROOT/"
chmod +x "$DMGROOT/Install.command" "$DMGROOT/Uninstall.command"

cat > "$DMGROOT/README.txt" <<TXT
Mouse Studio ${VERSION}

This build is ad-hoc signed (not notarized), so macOS Gatekeeper blocks the
installer if you double-click it. Install from Terminal instead — it's easy:

  1. Open Terminal (press Cmd-Space, type "Terminal", Enter).
  2. Type:  bash    (with a trailing space)
  3. Drag the Install.command file from this window into the Terminal window,
     then press Enter.
     (Or run: bash "/Volumes/Mouse Studio ${VERSION}/Install.command")
  4. Grant Accessibility permission to MouseStudioService in
     System Settings › Privacy & Security › Accessibility.

The installer clears the quarantine flag, so the apps open normally afterwards.

To remove:  bash "/Volumes/Mouse Studio ${VERSION}/Uninstall.command"
TXT

echo "==> Building disk image…"
DMG="$DIST/MouseStudio-${VERSION}.dmg"
hdiutil create -volname "Mouse Studio ${VERSION}" -srcfolder "$DMGROOT" -ov -format UDZO "$DMG" >/dev/null
echo "==> Created $DMG"
