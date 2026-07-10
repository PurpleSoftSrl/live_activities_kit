import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'live_activities_kit_method_channel.dart';

abstract class LiveActivitiesPlatform extends PlatformInterface {
  LiveActivitiesPlatform() : super(token: _token);
  static final Object _token = Object();
  static LiveActivitiesPlatform _instance = MethodChannelLiveActivities();
  static LiveActivitiesPlatform get instance => _instance;
  static set instance(LiveActivitiesPlatform instance) { PlatformInterface.verifyToken(instance, _token); _instance = instance; }

  Future<bool> get isSupported;
  Future<bool> get areActivitiesEnabled;
  Future<bool> get frequentPushesEnabled;
  Future<bool> allowsPushStart();
  Future<bool> requestPermission();
  Future<String?> start(String id, LiveActivityData data, {List<Map<String, String>>? actions, String? tag, bool removeWhenAppIsKilled = false});
  Future<bool> update(String id, LiveActivityData data, {LiveActivityAlert? alert, String? tag});
  Future<bool> end(String id, {LiveActivityData? finalContent, LiveActivityDismissalPolicy policy = LiveActivityDismissalPolicy.immediate});
  Future<String?> createOrUpdate(String id, LiveActivityData data, {String? tag, bool removeWhenAppIsKilled = false});
  Future<List<String>> getAllIds();
  Future<Map<String, ActivityState>> getAllActivities();
  Future<ActivityState?> getActivityState(String id);
  Future<bool> endAll();
  Future<String?> getPushToken();
  Stream<String> get onPushToken;
  Stream<String> get onAction;
  Stream<String> get onUrlScheme;
  Stream<ActivityUpdate> get activityUpdateStream;
}

enum ActivityState { active, ended, dismissed, unknown }

sealed class ActivityUpdate {
  final String id;
  const ActivityUpdate(this.id);
}
class ActivityActive extends ActivityUpdate { final String? pushToken; const ActivityActive(super.id, {this.pushToken}); }
class ActivityEnded extends ActivityUpdate { const ActivityEnded(super.id); }
class ActivityStale extends ActivityUpdate { const ActivityStale(super.id); }
class ActivityDismissed extends ActivityUpdate { const ActivityDismissed(super.id); }

class LiveActivityData {
  final String title; final String? subtitle; final double? progress; final String? trailingText; final String? leadingIcon;
  final bool wakeScreen; final double? staleMinutes; final double? relevanceScore; final int? color; final bool wantsPushToken; final LiveActivityImage? image;
  const LiveActivityData({required this.title, this.subtitle, this.progress, this.trailingText, this.leadingIcon, this.wakeScreen = false, this.staleMinutes, this.relevanceScore, this.color, this.wantsPushToken = false, this.image});
  Map<String, dynamic> toMap() => {'title': title, if (subtitle != null) 'subtitle': subtitle, if (progress != null) 'progress': progress, if (trailingText != null) 'trailingText': trailingText, if (leadingIcon != null) 'leadingIcon': leadingIcon, 'wakeScreen': wakeScreen, if (staleMinutes != null) 'staleMinutes': staleMinutes, if (relevanceScore != null) 'relevanceScore': relevanceScore, if (color != null) 'color': color, 'wantsPushToken': wantsPushToken, if (image != null) 'imagePath': image!.path};
}

class LiveActivityAlert {
  final String title; final String? body; final bool playSound;
  const LiveActivityAlert({required this.title, this.body, this.playSound = true});
  Map<String, dynamic> toMap() => {'alertTitle': title, if (body != null) 'alertBody': body, 'playSound': playSound};
}

enum LiveActivityDismissalPolicy { immediate, default_, afterDuration }

abstract class LiveActivityImage {
  String get path; int? get resizeWidth; int? get resizeHeight;
  const LiveActivityImage();
  factory LiveActivityImage.fromAsset(String path, {int? resizeWidth, int? resizeHeight}) = _AssetImage;
  factory LiveActivityImage.fromUrl(String url, {int? resizeWidth, int? resizeHeight}) = _UrlImage;
  factory LiveActivityImage.fromMemory(String tempPath, {int? resizeWidth, int? resizeHeight}) = _MemoryImage;
}
class _AssetImage extends LiveActivityImage { @override final String path; @override final int? resizeWidth; @override final int? resizeHeight; const _AssetImage(this.path, {this.resizeWidth, this.resizeHeight}); }
class _UrlImage extends LiveActivityImage { @override final String path; @override final int? resizeWidth; @override final int? resizeHeight; const _UrlImage(this.path, {this.resizeWidth, this.resizeHeight}); }
class _MemoryImage extends LiveActivityImage { @override final String path; @override final int? resizeWidth; @override final int? resizeHeight; const _MemoryImage(this.path, {this.resizeWidth, this.resizeHeight}); }
