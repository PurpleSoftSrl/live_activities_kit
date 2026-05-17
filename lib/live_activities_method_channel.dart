import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'live_activities_platform_interface.dart';

class MethodChannelLiveActivities extends LiveActivitiesPlatform {
  @visibleForTesting static const methodChannel = MethodChannel('live_activities');
  @visibleForTesting static const pushTokenEvents = EventChannel('live_activities/pushToken');
  @visibleForTesting static const actionEvents = EventChannel('live_activities/actions');
  @visibleForTesting static const urlSchemeEvents = EventChannel('live_activities/urlScheme');
  @visibleForTesting static const activityEvents = EventChannel('live_activities/activityUpdate');

  @override Future<bool> get isSupported async => await methodChannel.invokeMethod<bool>('isSupported') ?? false;
  @override Future<bool> get areActivitiesEnabled async => await methodChannel.invokeMethod<bool>('areActivitiesEnabled') ?? false;
  @override Future<bool> get frequentPushesEnabled async => await methodChannel.invokeMethod<bool>('frequentPushesEnabled') ?? false;
  @override Future<bool> allowsPushStart() async => await methodChannel.invokeMethod<bool>('allowsPushStart') ?? false;
  @override Future<bool> requestPermission() async => await methodChannel.invokeMethod<bool>('requestPermission') ?? false;

  @override Future<String?> start(String id, LiveActivityData data, {List<Map<String, String>>? actions, String? tag, bool removeWhenAppIsKilled = false}) async {
    final args = <String, dynamic>{'id': id, 'removeWhenAppIsKilled': removeWhenAppIsKilled, ...data.toMap()};
    if (actions != null) args['actions'] = actions;
    if (tag != null) args['tag'] = tag;
    return await methodChannel.invokeMethod<String>('start', args);
  }
  @override Future<bool> update(String id, LiveActivityData data, {LiveActivityAlert? alert, String? tag}) async {
    final args = <String, dynamic>{'id': id, ...data.toMap()}; if (tag != null) args['tag'] = tag; if (alert != null) args.addAll(alert.toMap());
    return await methodChannel.invokeMethod<bool>('update', args) ?? false;
  }
  @override Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate}) async {
    final args = <String, dynamic>{'id': id, 'policy': policy.name}; if (finalContent != null) args.addAll(finalContent.toMap());
    return await methodChannel.invokeMethod<bool>('end', args) ?? false;
  }
  @override Future<String?> createOrUpdate(String id, LiveActivityData data, {String? tag, bool removeWhenAppIsKilled = false}) async {
    final args = <String, dynamic>{'id': id, 'removeWhenAppIsKilled': removeWhenAppIsKilled, ...data.toMap()}; if (tag != null) args['tag'] = tag;
    return await methodChannel.invokeMethod<String>('createOrUpdate', args);
  }
  @override Future<List<String>> getAllIds() async => (await methodChannel.invokeListMethod<String>('getAllIds'))?.cast<String>() ?? [];
  @override Future<Map<String, ActivityState>> getAllActivities() async {
    final r = await methodChannel.invokeMapMethod<String, String>('getAllActivities'); if (r == null) return {};
    return r.map((k, v) => MapEntry(k, ActivityState.values.firstWhere((e) => e.name == v, orElse: () => ActivityState.unknown)));
  }
  @override Future<ActivityState?> getActivityState(String id) async {
    final r = await methodChannel.invokeMethod<String>('getActivityState', {'id': id});
    return r != null ? ActivityState.values.firstWhere((e) => e.name == r) : null;
  }
  @override Future<bool> endAll() async => await methodChannel.invokeMethod<bool>('endAll') ?? false;
  @override Future<String?> getPushToken() => methodChannel.invokeMethod<String>('getPushToken');
  @override Stream<String> get onPushToken => pushTokenEvents.receiveBroadcastStream().cast<String>();
  @override Stream<String> get onAction => actionEvents.receiveBroadcastStream().cast<String>();
  @override Stream<String> get onUrlScheme => urlSchemeEvents.receiveBroadcastStream().cast<String>();
  @override Stream<ActivityUpdate> get activityUpdateStream => activityEvents.receiveBroadcastStream().map((e) {
    final m = e as Map<dynamic, dynamic>; final id = m['id'] as String; final type = m['type'] as String;
    return switch (type) { 'active' => ActivityActive(id, pushToken: m['pushToken'] as String?), 'ended' => ActivityEnded(id), 'stale' => ActivityStale(id), 'dismissed' => ActivityDismissed(id), _ => ActivityEnded(id) };
  });
}
