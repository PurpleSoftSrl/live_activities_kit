# live_activities

> Live Activities & Dynamic Island for Flutter — iOS 16.1+ and Android heads-up notifications, with a specular API across both platforms.

[![pub.dev](https://img.shields.io/pub/v/live_activities?label=pub.dev&logo=dart&color=0175C2)](https://pub.dev/packages/live_activities)
[![CI](https://github.com/PurpleSoftSrl/live_activities/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/PurpleSoftSrl/live_activities/actions/workflows/ci.yml)
[![Publish](https://github.com/PurpleSoftSrl/live_activities/actions/workflows/publish.yml/badge.svg)](https://github.com/PurpleSoftSrl/live_activities/actions/workflows/publish.yml)
[![License](https://img.shields.io/badge/license-AGPL%20v3%20%7C%20Commercial-blue)](LICENSE)

## Features

- **iOS 16.1+**: Live Activities, Dynamic Island (compact, expanded, minimal), Lock Screen widgets
- **Android**: Progressive heads-up notifications with chronometer, BigTextStyle, action buttons
- **Specular API**: Identical `start()/update()/end()` calls for both platforms
- **Reactive streams**: `LiveActivity.run(id, stream)` auto-updates from any data source
- **Timer mode**: Built-in countdown with auto-end
- **Action buttons**: Android notification buttons with Flutter-side callbacks
- **Push-to-start**: iOS push token extraction for remote updates
- **Alert configuration**: Per-update alert with title, body, and sound
- **Dismissal policies**: `immediate`, `afterDuration`, `default_` (4h linger)
- **Activity content**: `staleDate`, `relevanceScore`, progress, color, SF Symbol icons

## Quick Start

```dart
import 'package:live_activities/live_activities.dart';

// Check support
if (!await LiveActivity.isSupported) return;

// Start
await LiveActivity.start(id: 'order-123', data: LiveActivityData(
  title: 'Preparing your order',
  progress: 0.2,
  leadingIcon: 'bag.fill',
  color: 0xFF1A73E8,
));

// Update with alert
await LiveActivity.update(id: 'order-123', data: LiveActivityData(
  title: 'Your order is ready!', progress: 1.0,
), alert: LiveActivityAlert(title: 'Ready!', body: 'Pick up at counter 3'));

// End with 1-hour linger
await LiveActivity.end('order-123', policy: LiveActivityDismissalPolicy.afterDuration);

// Reactive stream
LiveActivity.run(id: 'live-updates', stream: myStream.map((e) => LiveActivityData(title: e.status)));

// Timer countdown
LiveActivity.timer(id: 'eta', title: 'Delivery', duration: Duration(minutes: 15));
```

## Installation

```yaml
dependencies:
  live_activities: ^0.1.0
```

### iOS Setup

1. Run `scripts/setup_ios_widgetkit.sh` from your project root
2. Open `ios/Runner.xcworkspace` in Xcode
3. Add WidgetKit Extension target (see script output for steps)
4. Enable App Groups for both targets

### Android Setup

The plugin handles permission requests automatically on Android 13+.

## License

AGPL v3 for open-source use. Commercial license available at [developers@purplesoft.io](mailto:developers@purplesoft.io).
