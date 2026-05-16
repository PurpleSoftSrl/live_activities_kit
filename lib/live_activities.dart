import 'dart:async';

import 'live_activities_platform_interface.dart';

/// Flutter plugin for Live Activities and Dynamic Island.
///
/// iOS 16.1+ Live Activities + Android heads-up notifications.
///
/// ```dart
/// // Basic
/// await LiveActivity.start(id: 'o1', data: data);
///
/// // With alert on update
/// await LiveActivity.update(id: 'o1', data: data, alert: LiveActivityAlert(title: 'Ready!'));
///
/// // End with delay
/// await LiveActivity.end('o1', policy: LiveActivityDismissalPolicy.afterDuration, duration: Duration(hours: 1));
///
/// // Reactive stream
/// LiveActivity.run(id: 'o2', stream: orderStream.map((o) => data));
///
/// // Timer countdown
/// LiveActivity.timer(id: 't1', title: 'Delivery', duration: Duration(minutes: 15));
/// ```
class LiveActivity {
  LiveActivity._();

  static LiveActivitiesPlatform get _platform => LiveActivitiesPlatform.instance;

  static Future<bool> get isSupported => _platform.isSupported();
  static Future<bool> get frequentPushesEnabled => _platform.frequentPushesEnabled;

  static Future<bool> start({required String id, required LiveActivityData data}) =>
      _platform.start(id, data);

  static Future<bool> update({required String id, required LiveActivityData data, LiveActivityAlert? alert}) =>
      _platform.update(id, data, alert);

  static Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate, Duration? duration}) async =>
      _platform.end(id, finalContent: finalContent, policy: policy);

  static Future<List<String>> get allIds => _platform.getAllIds();
  static Future<bool> endAll() => _platform.endAll();

  static Future<String?> getPushToken() => _platform.getPushToken();
  static Stream<String> get onPushToken => _platform.onPushToken;
  static Stream<String> get onAction => _platform.onAction;

  static Future<bool> startWithActions({
    required String id,
    required LiveActivityData data,
    Map<String, String> actions = const {},
  }) => _platform.start(id, data, _mapToList(actions));

  static StreamSubscription<LiveActivityData> run({
    required String id,
    required Stream<LiveActivityData> stream,
    bool autoEnd = true,
    void Function(Object error)? onError,
  }) {
    bool started = false;
    final sub = stream.listen((data) async {
      if (!started) { await start(id: id, data: data); started = true; }
      else { await update(id: id, data: data); }
    }, onError: onError, onDone: () async {
      if (autoEnd && started) await end(id);
    }, cancelOnError: false);
    return sub;
  }

  static Future<StreamSubscription<void>> timer({
    required String id,
    required String title,
    String? subtitle,
    required Duration duration,
    void Function()? onExpired,
  }) async {
    final endTime = DateTime.now().add(duration);
    final total = duration.inSeconds.toDouble();
    await start(id: id, data: LiveActivityData(title: title, subtitle: subtitle, progress: 0, trailingText: _fmt(duration)));
    final sub = Stream<void>.periodic(const Duration(seconds: 1)).listen((_) async {
      final remaining = endTime.difference(DateTime.now());
      if (remaining.isNegative) {
        await update(id: id, data: LiveActivityData(title: '$title — Arrived!', subtitle: subtitle, progress: 1));
        await Future.delayed(const Duration(seconds: 3));
        await end(id);
        onExpired?.call();
      } else {
        await update(id: id, data: LiveActivityData(title: title, subtitle: subtitle,
            progress: ((total - remaining.inSeconds) / total).clamp(0, 1), trailingText: _fmt(remaining)));
      }
    });
    return sub;
  }

  static String _fmt(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  static List<Map<String, String>> _mapToList(Map<String, String> m) => m.entries.map((e) => {'id': e.key, 'label': e.value}).toList();
}
