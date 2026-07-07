#!/bin/bash
# Mouse Studio uninstaller: stops and removes the service and both apps.
# User configuration in ~/Library/Application Support/MouseStudio is preserved.
set -euo pipefail

AGENT="$HOME/Library/LaunchAgents/com.mousestudio.service.plist"

echo "Uninstalling Mouse Studio…"
launchctl unload "$AGENT" 2>/dev/null || true
rm -f "$AGENT"
rm -rf "/Applications/MouseStudio.app" "/Applications/MouseStudioService.app"

echo "Done. Your rules/profiles in ~/Library/Application Support/MouseStudio were kept."
echo "Delete that folder too if you want a full removal."
