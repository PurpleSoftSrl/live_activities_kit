import 'package:flutter_test/flutter_test.dart';
import 'package:live_activities_kit/live_activities_platform_interface.dart';

class MockLiveActivitiesPlatform extends LiveActivitiesPlatform {
  @override Future<bool> get isSupported => Future.value(true);
  @override Future<bool> get areActivitiesEnabled => Future.value(true);
  @override Future<bool> get frequentPushesEnabled => Future.value(false);
  @override Future<bool> allowsPushStart() => Future.value(false);
  @override Future<bool> requestPermission() => Future.value(true);
  @override Future<String?> start(String id, LiveActivityData data, {List<Map<String, String>>? actions, String? tag, bool removeWhenAppIsKilled = false}) => Future.value(id);
  @override Future<bool> update(String id, LiveActivityData data, {LiveActivityAlert? alert, String? tag}) => Future.value(true);
  @override Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate}) => Future.value(true);
  @override Future<String?> createOrUpdate(String id, LiveActivityData data, {String? tag, bool removeWhenAppIsKilled = false}) => Future.value(id);
  @override Future<List<String>> getAllIds() => Future.value(['id1','id2']);
  @override Future<Map<String, ActivityState>> getAllActivities() => Future.value({'id1': ActivityState.active, 'id2': ActivityState.ended});
  @override Future<ActivityState?> getActivityState(String id) => Future.value(id == 'id1' ? ActivityState.active : null);
  @override Future<bool> endAll() => Future.value(true);
  @override Future<String?> getPushToken() => Future.value(null);
  @override Stream<String> get onPushToken => const Stream.empty();
  @override Stream<String> get onAction => const Stream.empty();
  @override Stream<String> get onUrlScheme => const Stream.empty();
  @override Stream<ActivityUpdate> get activityUpdateStream => Stream.value(ActivityActive('id1', pushToken: 'tok123'));
}

void main() {
  late MockLiveActivitiesPlatform mock;
  setUp(() { mock = MockLiveActivitiesPlatform(); LiveActivitiesPlatform.instance = mock; });
  test('isSupported', () async => expect(await LiveActivitiesPlatform.instance.isSupported, isTrue));
  test('areActivitiesEnabled', () async => expect(await LiveActivitiesPlatform.instance.areActivitiesEnabled, isTrue));
  test('start returns id', () async => expect(await LiveActivitiesPlatform.instance.start('id', const LiveActivityData(title:'T')), 'id'));
  test('start with tag', () async => expect(await LiveActivitiesPlatform.instance.start('id', const LiveActivityData(title:'T'), tag:'mytag', removeWhenAppIsKilled:true), 'id'));
  test('getAllActivities returns map', () async { final m = await LiveActivitiesPlatform.instance.getAllActivities(); expect(m.length, 2); expect(m['id1'], ActivityState.active); });
  test('getActivityState returns state', () async => expect(await LiveActivitiesPlatform.instance.getActivityState('id1'), ActivityState.active));
  test('activityUpdateStream emits update', () async { final u = await LiveActivitiesPlatform.instance.activityUpdateStream.first; expect(u.id, 'id1'); expect(u, isA<ActivityActive>()); });
}
