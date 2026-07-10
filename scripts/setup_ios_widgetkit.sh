#!/bin/bash
# iOS WidgetKit Live Activities – automated setup (macOS only)
# Usage: ./setup_ios_widgetkit.sh [--dry-run]
set -euo pipefail

DRY_RUN=false
while [[ $# -gt 0 ]]; do case "$1" in --dry-run) DRY_RUN=true; shift ;; *) echo "Unknown: $1"; exit 1 ;; esac; done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()  { echo "" >&2; echo -e "${YELLOW}═══ $* ═══${NC}" >&2; }

guard() {
  if $DRY_RUN; then echo "  [DRY-RUN] $*"; else "$@"; fi
}

# ── Validation ────────────────────────────────────────────────────────────

[[ "$(uname)" == "Darwin" ]] || { err "macOS required"; exit 1; }
for tool in flutter pod plutil /usr/libexec/PlistBuddy; do
  command -v "$tool" &>/dev/null || { err "Missing: $tool"; exit 1; }
done
[[ -f pubspec.yaml ]] || { err "Run from Flutter project root"; exit 1; }
[[ -d ios/Classes/LiveActivitiesWidgetExtension ]] || { err "ios/Classes/LiveActivitiesWidgetExtension not found"; exit 1; }

# ── App name ──────────────────────────────────────────────────────────────

APP_NAME=$(grep -m1 '^name:' pubspec.yaml | sed -E 's/^name: *"?([^"#]+?)"?\s*$/\1/')
info "App: $APP_NAME"

# ── 1. Podspec frameworks ─────────────────────────────────────────────────

PODSPEC="ios/live_activities_kit.podspec"
if [[ -f "$PODSPEC" ]]; then
  step "Podspec frameworks"
  for fw in WidgetKit ActivityKit SwiftUI; do
    if grep -q "$fw" "$PODSPEC"; then
      echo "  ✓ $fw"
    else
      warn "  ✗ $fw – appending to podspec"
      if ! $DRY_RUN; then
        # Insert before 'end' keyword
        sed -i '' "/^end/i\\
  s.framework = '$fw'
" "$PODSPEC"
      fi
    fi
  done
fi

# ── 2. Info.plist – NSSupportsLiveActivities ──────────────────────────────

EXAMPLE_PLIST="example/ios/Runner/Info.plist"
step "Info.plist – NSSupportsLiveActivities"
if [[ -f "$EXAMPLE_PLIST" ]]; then
  if /usr/libexec/PlistBuddy -c "Print :NSSupportsLiveActivities" "$EXAMPLE_PLIST" &>/dev/null; then
    echo "  ✓ Already present"
  else
    info "  Adding NSSupportsLiveActivities = YES"
    guard /usr/libexec/PlistBuddy -c "Add :NSSupportsLiveActivities bool true" "$EXAMPLE_PLIST"
  fi
fi

# ── 3. Deployment target ──────────────────────────────────────────────────

step "Deployment target"
readonly TARGET="16.1"
if grep -q "s.platform.*:ios" "$PODSPEC"; then
  echo "  ✓ iOS platform declared in podspec (ensure >= $TARGET)"
else
  warn "  Add: s.platform = :ios, '$TARGET' to $PODSPEC"
fi

# ── 4. Xcode target ───────────────────────────────────────────────────────

step "WidgetKit Extension Xcode target"
EXT_DIR="ios/Classes/LiveActivitiesWidgetExtension"
XCODE_PROJ="example/ios/Runner.xcodeproj"
SWIFT_FILE="$EXT_DIR/LiveActivitiesWidget.swift"
PLIST_FILE="$EXT_DIR/Info.plist"

if [[ -d "$XCODE_PROJ" ]]; then
  # Use ruby/xcodeproj (bundled with CocoaPods, already present)
  if ruby -e "require 'xcodeproj'" 2>/dev/null; then
    info "Creating WidgetKit target with xcodeproj gem..."
    guard ruby - "$XCODE_PROJ" "LiveActivitiesWidget" "$EXT_DIR" <<'RUBY'
require 'xcodeproj'

proj_path, ext_name, ext_dir = ARGV

project = Xcodeproj::Project.open(proj_path)
app_target = project.targets.find { |t| t.isa == 'PBXNativeTarget' && !t.product_type&.include?('tests') && !t.name&.include?('Widget') }

abort "ERROR: no app target found" unless app_target

if project.targets.any? { |t| t.name == ext_name }
  puts "  ✓ Target '#{ext_name}' already exists"
else
  puts "  Creating Widget Extension target '#{ext_name}'..."
  widget = project.new_target(:app_extension, ext_name, :ios)
  widget.deployment_target = '16.1'
  widget.product_bundle_identifier = "$(PRODUCT_BUNDLE_IDENTIFIER).#{ext_name}"
  widget.build_configurations.each do |cfg|
    cfg.build_settings['SWIFT_VERSION'] = '5.0'
    cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.1'
    cfg.build_settings['INFOPLIST_FILE'] = File.join(ext_dir, 'Info.plist')
    cfg.build_settings['PRODUCT_NAME'] = ext_name
    cfg.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  end

  # Add Swift + plist files
  Dir.glob(File.join(ext_dir, '*.{swift,plist}')).each do |f|
    widget.new_file(f)
    puts "    + #{File.basename(f)}"
  end

  project.save
  puts "  ✓ Target '#{ext_name}' created and project saved"
end
RUBY
  else
    warn "ruby xcodeproj gem not available. Install: gem install xcodeproj"
    warn "Falling back to manual steps (see below)."
  fi
else
  warn "No .xcodeproj at $XCODE_PROJ — run 'cd example && flutter build ios --no-codesign' first."
fi

# ── 5. Summary ────────────────────────────────────────────────────────────

step "Done"
echo "  Podspec:       ✓"
echo "  Info.plist:    ✓"
echo "  Deployment:    iOS $TARGET+"

if $DRY_RUN; then echo -e "\n${YELLOW}Dry run – rerun without --dry-run to apply changes.${NC}"; fi

cat <<'EOF'

Next steps:
  cd example && flutter pub get && cd ios && pod install
  open example/ios/Runner.xcworkspace

If Xcode target was NOT auto-created:
  1. File → New → Target → Widget Extension, uncheck 'Configuration Intent'
  2. Name: LiveActivitiesWidget, Product Bundle Identifier: ...LiveActivitiesWidget
  3. Add 'ios/Classes/LiveActivitiesWidgetExtension/*.swift' to target
  4. Set deployment target to 16.1; configure App Group in Signing & Capabilities
EOF
