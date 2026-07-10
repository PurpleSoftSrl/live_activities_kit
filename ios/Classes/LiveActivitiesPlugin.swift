import Flutter
import ActivityKit

public class LiveActivitiesPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var pushTokenSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "live_activities_kit", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "live_activities_kit/pushToken", binaryMessenger: registrar.messenger())
        let urlSchemeChannel = FlutterEventChannel(name: "live_activities_kit/urlScheme", binaryMessenger: registrar.messenger())
        let activityChannel = FlutterEventChannel(name: "live_activities_kit/activityUpdate", binaryMessenger: registrar.messenger())
        let instance = LiveActivitiesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        urlSchemeChannel.setStreamHandler(UrlSchemeStreamHandler())
        activityChannel.setStreamHandler(ActivityUpdateStreamHandler())
    }

    // MARK: - Method handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported": result(isActivityKitAvailable())
        case "frequentPushesEnabled": result(isFrequentPushesEnabled())
        case "allowsPushStart": result(allowsPushStart())
        case "requestPermission": result(true)
        case "start": handleStart(call, result)
        case "update": handleUpdate(call, result)
        case "end": handleEnd(call, result)
        case "createOrUpdate": handleCreateOrUpdate(call, result)
        case "getAllIds": result(getAllActivityIds())
        case "endAll": endAll(result)
        case "getAllActivities": result(getAllActivitiesMap())
        case "getActivityState":
            guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else { result(nil); return }
            result(getActivityState(id: id))
        case "endAll": endAll(result)
        case "getPushToken": result(nil)
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Stream
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        pushTokenSink = events
        if #available(iOS 16.1, *) {
            Task { for await token in Activity<LiveActivityAttributes>.pushToStartTokenUpdates {
                pushTokenSink?(token.map { String(format: "%02x", $0) }.joined())
            }}
        }
        return nil
    }
    public func onCancel(withArguments arguments: Any?) -> FlutterError? { pushTokenSink = nil; return nil }

    // MARK: - Capability checks
    private func isActivityKitAvailable() -> Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    private func isFrequentPushesEnabled() -> Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().frequentPushesEnabled
    }
    private func allowsPushStart() -> Bool {
        guard #available(iOS 17.2, *) else { return false }
        return true
    }
    private func getAllActivityIds() -> [String] {
        guard #available(iOS 16.1, *) else { return [] }
        return Activity<LiveActivityAttributes>.activities.map { $0.attributes.id }
    }

    // MARK: - Lifecycle
    private func handleStart(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String, let title = args["title"] as? String else { result(false); return }
        let attrs = LiveActivityAttributes(id: id, title: title, subtitle: args["subtitle"] as? String, progress: args["progress"] as? Double ?? 0, trailingText: args["trailingText"] as? String, leadingIcon: args["leadingIcon"] as? String)
        let state = LiveActivityAttributes.ContentState(title: title, subtitle: args["subtitle"] as? String, progress: args["progress"] as? Double ?? 0, trailingText: args["trailingText"] as? String)
        let staleDate = (args["staleMinutes"] as? Double).map { Date.now.addingTimeInterval($0 * 60) }
        let relevance = (args["relevanceScore"] as? Double).map { Double($0) }
        let wantsPushToken = args["wantsPushToken"] as? Bool ?? false
        do {
            let activity = try Activity.request(attributes: attrs, content: .init(state: state, staleDate: staleDate, relevanceScore: relevance), pushType: wantsPushToken ? .token : nil)
            if wantsPushToken {
                Task { for await tokenData in activity.pushTokenUpdates { pushTokenSink?(tokenData.map { String(format: "%02x", $0) }.joined()) }}
            }
            result(true)
        } catch { result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil)) }
    }

    private func handleUpdate(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String, let title = args["title"] as? String else { result(false); return }
        Task {
            let state = LiveActivityAttributes.ContentState(title: title, subtitle: args["subtitle"] as? String, progress: args["progress"] as? Double ?? 0, trailingText: args["trailingText"] as? String)
            let staleDate = (args["staleMinutes"] as? Double).map { Date.now.addingTimeInterval($0 * 60) }
            let relevance = (args["relevanceScore"] as? Double).map { Double($0) }
            let content = ActivityContent(state: state, staleDate: staleDate, relevanceScore: relevance)
            let alertConfig: AlertConfiguration? = (args["alertTitle"] as? String).map { AlertConfiguration(title: .init(stringLiteral: $0), body: (args["alertBody"] as? String).map { .init(stringLiteral: $0) } ?? .init(stringLiteral: ""), sound: (args["playSound"] as? Bool ?? true) ? .default : nil) }
            for activity in Activity<LiveActivityAttributes>.activities where activity.attributes.id == id {
                if let ac = alertConfig { await activity.update(content, alertConfiguration: ac) } else { await activity.update(content) }
                result(true); return
            }
            result(false)
        }
    }

    private func handleEnd(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else { result(false); return }
        Task {
            let policyStr = args["policy"] as? String ?? "immediate"
            let policy: ActivityUIDismissalPolicy = policyStr == "default_" ? .default : policyStr == "afterDuration" ? .after(.now + 3600) : .immediate
            for activity in Activity<LiveActivityAttributes>.activities where activity.attributes.id == id {
                await activity.end(dismissalPolicy: policy); result(true); return
            }
            result(false)
        }
    }

    private func handleCreateOrUpdate(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else { result(nil); return }
        for activity in Activity<LiveActivityAttributes>.activities where activity.attributes.id == id {
            handleUpdate(call, result); return
        }
        handleStart(call, result)
    }

    private func endAll(_ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        Task {
            for activity in Activity<LiveActivityAttributes>.activities { await activity.end(dismissalPolicy: .immediate) }
            result(true)
        }
    }
    private func getAllActivitiesMap() -> [String: String] {
        guard #available(iOS 16.1, *) else { return [:] }
        var map = [String: String]()
        for activity in Activity<LiveActivityAttributes>.activities { map[activity.attributes.id] = "active" }
        return map
    }

    private func getActivityState(id: String) -> String? {
        guard #available(iOS 16.1, *) else { return nil }
        for activity in Activity<LiveActivityAttributes>.activities where activity.attributes.id == id { return "active" }
        return nil
    }
}

// MARK: - URL Scheme handler
class UrlSchemeStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? { return nil }
    func onCancel(withArguments arguments: Any?) -> FlutterError? { return nil }
}

class ActivityUpdateStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard #available(iOS 16.1, *) else { return nil }
        Task {
            for await activity in Activity<LiveActivityAttributes>.activityUpdates {
                let type = switch activity.activityState {
                    case .active: "active"; case .ended: "ended"; case .dismissed: "dismissed"; case .stale: "stale"; @unknown default: "unknown"
                }
                let pushToken = activity.pushTokenUpdates.first.flatMap { _ in (activity as? Activity<LiveActivityAttributes>)?.pushToken }.map { "" } // simplified
                events(["id": activity.attributes.id, "type": type])
            }
        }
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? { return nil }
}

// MARK: - ActivityKit Types
@available(iOS 16.1, *)
struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable { var title: String; var subtitle: String?; var progress: Double; var trailingText: String? }
    var id: String; var title: String; var subtitle: String?; var progress: Double; var trailingText: String?; var leadingIcon: String?
}
