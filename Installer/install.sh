#!/bin/bash
# Mouse Studio installer: copies both apps to /Applications and registers the
# background service to start at login.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
AGENT="$HOME/Library/LaunchAgents/com.mousestudio.service.plist"

echo "Installing Mouse Studio…"

# Remove older copies, then install fresh.
rm -rf "/Applications/MouseStudio.app" "/Applications/MouseStudioService.app"
cp -R "$HERE/MouseStudio.app" /Applications/
cp -R "$HERE/MouseStudioService.app" /Applications/

# This build is ad-hoc signed (not notarized). Clear the quarantine flag on the
# installed apps so they launch without a Gatekeeper prompt.
xattr -dr com.apple.quarantine "/Applications/MouseStudio.app" 2>/dev/null || true
xattr -dr com.apple.quarantine "/Applications/MouseStudioService.app" 2>/dev/null || true

# Register the background service (LaunchAgent).
mkdir -p "$HOME/Library/LaunchAgents"
cp "$HERE/com.mousestudio.service.plist" "$AGENT"
launchctl unload "$AGENT" 2>/dev/null || true
launchctl load "$AGENT"

echo ""
echo "Installed. Opening Mouse Studio…"
open "/Applications/MouseStudio.app" || true
echo ""
echo "IMPORTANT: grant Accessibility permission to MouseStudioService in"
echo "System Settings › Privacy & Security › Accessibility, then the mouse"
echo "buttons will start working."
