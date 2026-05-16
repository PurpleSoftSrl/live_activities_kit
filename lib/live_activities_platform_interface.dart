import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'live_activities_method_channel.dart';

/// Abstract platform interface for Live Activities + Dynamic Island.
abstract class LiveActivitiesPlatform extends PlatformInterface {
  LiveActivitiesPlatform() : super(token: _token);

  static final Object _token = Object();
  static LiveActivitiesPlatform _instance = MethodChannelLiveActivities();

  static LiveActivitiesPlatform get instance => _instance;
  static set instance(LiveActivitiesPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isSupported();
  Future<bool> get frequentPushesEnabled;
  Future<bool> start(String id, LiveActivityData data, [List<Map<String, String>>? actions]);
  Future<bool> update(String id, LiveActivityData data, [LiveActivityAlert? alert]);
  Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate});
  Future<String?> getPushToken();
  Stream<String> get onPushToken;
  Stream<String> get onAction;
}

/// Data model for a Live Activity's content.
class LiveActivityData {
  final String title;
  final String? subtitle;
  final double? progress;
  final String? trailingText;
  final String? leadingIcon;
  final bool wakeScreen;
  final double? staleMinutes;
  final double? relevanceScore;
  final int? color;
  final bool wantsPushToken;

  const LiveActivityData({
    required this.title,
    this.subtitle,
    this.progress,
    this.trailingText,
    this.leadingIcon,
    this.wakeScreen = false,
    this.staleMinutes,
    this.relevanceScore,
    this.color,
    this.wantsPushToken = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (progress != null) 'progress': progress,
        if (trailingText != null) 'trailingText': trailingText,
        if (leadingIcon != null) 'leadingIcon': leadingIcon,
        'wakeScreen': wakeScreen,
        if (staleMinutes != null) 'staleMinutes': staleMinutes,
        if (relevanceScore != null) 'relevanceScore': relevanceScore,
        if (color != null) 'color': color,
        'wantsPushToken': wantsPushToken,
      };
}

/// Alert configuration for a Live Activity update.
class LiveActivityAlert {
  final String title;
  final String? body;
  final bool playSound;

  const LiveActivityAlert({required this.title, this.body, this.playSound = true});

  Map<String, dynamic> toMap() => {
        'alertTitle': title,
        if (body != null) 'alertBody': body,
        'playSound': playSound,
      };
}

/// Dismissal policy when ending a Live Activity.
enum LiveActivityDismissalPolicy {
  immediate,
  default_,
  afterDuration,
}
