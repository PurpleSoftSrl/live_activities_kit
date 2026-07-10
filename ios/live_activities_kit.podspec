Pod::Spec.new do |s|
  s.name             = 'live_activities_kit'
  s.version          = '0.1.0'
  s.summary          = 'Live Activities and Dynamic Island for Flutter. iOS 16.1+, Android heads-up notifications.'
  s.description      = <<-DESC
Live Activities and Dynamic Island plugin for Flutter. Supports iOS 16.1+ Live Activities
with Dynamic Island, Lock Screen widgets, and Android heads-up progress notifications.
                      DESC
  s.homepage         = 'https://github.com/PurpleSoftSrl/live_activities_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PurpleSoft' => 'developers@purplesoft.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.1'
  s.frameworks = 'WidgetKit', 'ActivityKit', 'SwiftUI'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
