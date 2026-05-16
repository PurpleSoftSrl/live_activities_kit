import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'live_activities_platform_interface.dart';

class MethodChannelLiveActivities extends LiveActivitiesPlatform {
  @visibleForTesting static const methodChannel = MethodChannel('live_activities');
  @visibleForTesting static const pushTokenEvents = EventChannel('live_activities/pushToken');
  @visibleForTesting static const actionEvents = EventChannel('live_activities/actions');

  @override
  Future<bool> isSupported() async => await methodChannel.invokeMethod<bool>('isSupported') ?? false;

  @override
  Future<bool> get frequentPushesEnabled async => await methodChannel.invokeMethod<bool>('frequentPushesEnabled') ?? false;

  @override
  Future<bool> start(String id, LiveActivityData data, [List<Map<String, String>>? actions]) async {
    final args = <String, dynamic>{'id': id, ...data.toMap()};
    if (actions != null) args['actions'] = actions;
    return await methodChannel.invokeMethod<bool>('start', args) ?? false;
  }

  @override
  Future<bool> update(String id, LiveActivityData data, [LiveActivityAlert? alert]) async {
    final args = <String, dynamic>{'id': id, ...data.toMap()};
    if (alert != null) args.addAll(alert.toMap());
    return await methodChannel.invokeMethod<bool>('update', args) ?? false;
  }

  @override
  Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate}) async {
    final args = <String, dynamic>{'id': id, 'policy': policy.name};
    if (finalContent != null) args.addAll(finalContent.toMap());
    return await methodChannel.invokeMethod<bool>('end', args) ?? false;
  }

  @override
  Future<List<String>> getAllIds() async {
    final result = await methodChannel.invokeListMethod<String>('getAllIds');
    return result?.cast<String>() ?? [];
  }

  @override
  Future<bool> endAll() async {
    return await methodChannel.invokeMethod<bool>('endAll') ?? false;
  }

  @override Future<String?> getPushToken() => methodChannel.invokeMethod<String>('getPushToken');
  @override Stream<String> get onPushToken => pushTokenEvents.receiveBroadcastStream().cast<String>();
  @override Stream<String> get onAction => actionEvents.receiveBroadcastStream().cast<String>();
}
