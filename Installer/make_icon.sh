#!/bin/bash
# Generates Installer/AppIcon.icns — a modern gradient tile with a white mouse
# glyph. Requires macOS (AppKit + iconutil + sips). Run from the repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/gen.swift" <<'SWIFT'
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let clip = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)
clip.addClip()
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.36, green: 0.34, blue: 0.92, alpha: 1),
    NSColor(calibratedRed: 0.62, green: 0.29, blue: 0.90, alpha: 1)
])!
gradient.draw(in: rect, angle: -55)

if let symbol = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: 560, weight: .regular)
    if let glyph = symbol.withSymbolConfiguration(config) {
        let gs = glyph.size
        let tinted = NSImage(size: gs)
        tinted.lockFocus()
        glyph.draw(in: NSRect(origin: .zero, size: gs))
        NSColor.white.set()
        NSRect(origin: .zero, size: gs).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.draw(in: NSRect(x: (size - gs.width) / 2, y: (size - gs.height) / 2, width: gs.width, height: gs.height))
    }
}

image.unlockFocus()

let tiff = image.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
SWIFT

swift "$WORK/gen.swift" "$WORK/base.png"

ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
gen() { sips -z "$1" "$1" "$WORK/base.png" --out "$ICONSET/$2" >/dev/null; }
gen 16   icon_16x16.png
gen 32   icon_16x16@2x.png
gen 32   icon_32x32.png
gen 64   icon_32x32@2x.png
gen 128  icon_128x128.png
gen 256  icon_128x128@2x.png
gen 256  icon_256x256.png
gen 512  icon_256x256@2x.png
gen 512  icon_512x512.png
gen 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o "$ROOT/Installer/AppIcon.icns"
echo "Wrote $ROOT/Installer/AppIcon.icns"
