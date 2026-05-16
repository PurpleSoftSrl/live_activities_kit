import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_activities/live_activities_method_channel.dart';
import 'package:live_activities/live_activities_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelLiveActivities', () {
    const channel = MethodChannel('live_activities');
    final handler = MethodChannelLiveActivities();

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isSupported returns false when channel fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      expect(await handler.isSupported(), isFalse);
    });

    test('start returns false when channel fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);
      expect(await handler.start('id', const LiveActivityData(title: 'T')), isFalse);
    });

    test('end returns false when channel fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);
      expect(await handler.end('id'), isFalse);
    });
  });
}
