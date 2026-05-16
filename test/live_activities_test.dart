import 'package:flutter_test/flutter_test.dart';
import 'package:live_activities_kit/live_activities_platform_interface.dart';

class MockLiveActivitiesPlatform extends LiveActivitiesPlatform {
  @override Future<bool> isSupported() => Future.value(true);
  @override Future<bool> get frequentPushesEnabled => Future.value(false);
  @override Future<bool> start(String id, LiveActivityData data, [List<Map<String, String>>? a]) => Future.value(true);
  @override Future<bool> update(String id, LiveActivityData data, [LiveActivityAlert? alert]) => Future.value(true);
  @override Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate}) => Future.value(true);
  @override Future<List<String>> getAllIds() => Future.value(['id1']);
  @override Future<bool> endAll() => Future.value(true);
  @override Future<String?> getPushToken() => Future.value(null);
  @override Stream<String> get onPushToken => const Stream.empty();
  @override Stream<String> get onAction => const Stream.empty();
}

void main() {
  late MockLiveActivitiesPlatform mock;
  setUp(() {
    mock = MockLiveActivitiesPlatform();
    LiveActivitiesPlatform.instance = mock;
  });

  test('isSupported returns true on mock', () async => expect(await LiveActivitiesPlatform.instance.isSupported(), isTrue));
  test('start returns true', () async => expect(await LiveActivitiesPlatform.instance.start('id', const LiveActivityData(title: 'T')), isTrue));
  test('update with alert', () async => expect(await LiveActivitiesPlatform.instance.update('id', const LiveActivityData(title: 'U'), LiveActivityAlert(title: 'A')), isTrue));
  test('end with policy', () async => expect(await LiveActivitiesPlatform.instance.end('id', policy: LiveActivityDismissalPolicy.afterDuration), isTrue));
  test('getAllIds returns list', () async => expect(await LiveActivitiesPlatform.instance.getAllIds(), ['id1']));
  test('endAll returns true', () async => expect(await LiveActivitiesPlatform.instance.endAll(), isTrue));
  test('LiveActivityData serializes correctly', () {
    final m = const LiveActivityData(title: 'T', progress: 0.5, staleMinutes: 5, color: 0xFF123456).toMap();
    expect(m['title'], 'T'); expect(m['staleMinutes'], 5); expect(m['color'], 0xFF123456);
  });
}

