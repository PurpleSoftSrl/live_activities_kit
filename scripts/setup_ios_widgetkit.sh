#!/bin/bash
# Setup iOS WidgetKit Extension for Live Activities
# Run this from your Flutter project root (the directory with ios/ folder)

set -e

EXT_DIR="ios/Classes/LiveActivitiesWidgetExtension"
APP_NAME=$(grep "^name:" pubspec.yaml | awk '{print $2}')

echo "Setting up WidgetKit Extension for Live Activities..."
echo "  App name: $APP_NAME"

# 1. Ensure WidgetKit is in the podspec
PODSPEC="ios/live_activities.podspec"
if [ -f "$PODSPEC" ]; then
    if ! grep -q "s.framework.*WidgetKit" "$PODSPEC"; then
        echo "  Adding WidgetKit framework to podspec..."
        sed -i.bak "/s.ios.deployment_target/a\  s.framework = 'WidgetKit'\n  s.framework = 'ActivityKit'\n  s.framework = 'SwiftUI'" "$PODSPEC"
        rm -f "${PODSPEC}.bak"
    fi
else
    echo "  ⚠️  No podspec found at $PODSPEC"
fi

# 2. Add NSSupportsLiveActivities to example app's Info.plist
EXAMPLE_PLIST="example/ios/Runner/Info.plist"
if [ -f "$EXAMPLE_PLIST" ]; then
    if ! grep -q "NSSupportsLiveActivities" "$EXAMPLE_PLIST"; then
        echo "  Adding NSSupportsLiveActivities to example Info.plist..."
        python3 -c "
import plistlib
with open('$EXAMPLE_PLIST', 'rb') as f:
    plist = plistlib.load(f)
plist['NSSupportsLiveActivities'] = True
with open('$EXAMPLE_PLIST', 'wb') as f:
    plistlib.dump(plist, f)
" 2>/dev/null || echo "  ⚠️  Could not update Info.plist (install plistlib)"
    fi
fi

# 3. Instructions for manual Xcode steps
echo ""
echo "═══ Manual Xcode Steps ═══"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. File → New → Target → Widget Extension"
echo "3. Name: LiveActivitiesWidget"
echo "4. Uncheck 'Include Configuration Intent'"
echo "5. Delete generated files, copy ours from:"
echo "     ios/Classes/LiveActivitiesWidgetExtension/"
echo "6. Set deployment target to iOS 16.1"
echo "7. Add both targets to the same App Group"
echo "8. Build & Run"
echo ""
echo "Done! WidgetKit extension files are ready at: $EXT_DIR"
