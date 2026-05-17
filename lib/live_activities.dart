import 'dart:async';
import 'live_activities_platform_interface.dart';

class LiveActivity {
  LiveActivity._(); static LiveActivitiesPlatform get _p => LiveActivitiesPlatform.instance;
  static Future<bool> get isSupported => _p.isSupported;
  static Future<bool> get areActivitiesEnabled => _p.areActivitiesEnabled;
  static Future<bool> get frequentPushesEnabled => _p.frequentPushesEnabled;
  static Future<bool> allowsPushStart() => _p.allowsPushStart();
  static Future<bool> requestPermission() => _p.requestPermission();
  static Future<String?> start({required String id, required LiveActivityData data, String? tag, bool removeWhenAppIsKilled = false}) => _p.start(id, data, tag: tag, removeWhenAppIsKilled: removeWhenAppIsKilled);
  static Future<bool> update({required String id, required LiveActivityData data, LiveActivityAlert? alert, String? tag}) => _p.update(id, data, alert: alert, tag: tag);
  static Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate}) => _p.end(id, finalContent: finalContent, policy: policy);
  static Future<String?> createOrUpdate({required String id, required LiveActivityData data, String? tag, bool removeWhenAppIsKilled = false}) => _p.createOrUpdate(id, data, tag: tag, removeWhenAppIsKilled: removeWhenAppIsKilled);
  static Future<List<String>> get allIds => _p.getAllIds();
  static Future<Map<String, ActivityState>> getAllActivities() => _p.getAllActivities();
  static Future<ActivityState?> getActivityState(String id) => _p.getActivityState(id);
  static Future<bool> endAll() => _p.endAll();
  static Future<String?> getPushToken() => _p.getPushToken();
  static Stream<String> get onPushToken => _p.onPushToken;
  static Stream<String> get onAction => _p.onAction;
  static Stream<String> get onUrlScheme => _p.onUrlScheme;
  static Stream<ActivityUpdate> get activityUpdateStream => _p.activityUpdateStream;
  static Future<bool> startWithActions({required String id, required LiveActivityData data, Map<String, String> actions = const {}}) async { await _p.start(id, data, actions: _m(actions)); return true; }
  static StreamSubscription<LiveActivityData> run({required String id, required Stream<LiveActivityData> stream, bool autoEnd = true, void Function(Object error)? onError}) {
    bool started = false; return stream.listen((data) async { if (!started) { await start(id: id, data: data); started = true; } else { await update(id: id, data: data); } }, onError: onError, onDone: () async { if (autoEnd && started) await end(id); }, cancelOnError: false);
  }
  static Future<StreamSubscription<void>> timer({required String id, required String title, String? subtitle, required Duration duration, void Function()? onExpired}) async {
    final endTime = DateTime.now().add(duration); final total = duration.inSeconds.toDouble(); await start(id: id, data: LiveActivityData(title: title, subtitle: subtitle, progress: 0, trailingText: _f(duration)));
    return Stream<void>.periodic(const Duration(seconds: 1)).listen((_) async {
      final remaining = endTime.difference(DateTime.now()); if (remaining.isNegative) { await update(id: id, data: LiveActivityData(title: '$title — Arrived!', subtitle: subtitle, progress: 1)); await Future.delayed(const Duration(seconds: 3)); await end(id); onExpired?.call(); }
      else { await update(id: id, data: LiveActivityData(title: title, subtitle: subtitle, progress: ((total - remaining.inSeconds) / total).clamp(0, 1), trailingText: _f(remaining))); }
    });
  }
  static String _f(Duration d) => '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';
  static List<Map<String, String>> _m(Map<String, String> m) => m.entries.map((e) => {'id': e.key, 'label': e.value}).toList();
}
