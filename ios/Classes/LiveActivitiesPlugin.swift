import Flutter
import ActivityKit

public class LiveActivitiesPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var pushTokenSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "live_activities", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "live_activities/pushToken", binaryMessenger: registrar.messenger())
        let instance = LiveActivitiesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            result(isActivityKitAvailable())
        case "frequentPushesEnabled":
            result(isFrequentPushesEnabled())
        case "start":
            handleStart(call, result)
        case "update":
            handleUpdate(call, result)
        case "end":
            handleEnd(call, result)
        case "getPushToken":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Stream
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        pushTokenSink = events
        if #available(iOS 16.1, *) {
            Task {
                for await token in Activity<LiveActivityAttributes>.pushToStartTokenUpdates {
                    pushTokenSink?(token.map { String(format: "%02x", $0) }.joined())
                }
            }
        }
        return nil
    }
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        pushTokenSink = nil
        return nil
    }

    // MARK: - Handlers
    private func isActivityKitAvailable() -> Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func isFrequentPushesEnabled() -> Bool {
        guard #available(iOS 16.1, *) else { return false }
        return ActivityAuthorizationInfo().frequentPushesEnabled
    }

    private func handleStart(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String,
              let title = args["title"] as? String else { result(false); return }

        let attrs = LiveActivityAttributes(id: id, title: title,
            subtitle: args["subtitle"] as? String, progress: args["progress"] as? Double ?? 0,
            trailingText: args["trailingText"] as? String, leadingIcon: args["leadingIcon"] as? String)
        let state = LiveActivityAttributes.ContentState(title: title,
            subtitle: args["subtitle"] as? String, progress: args["progress"] as? Double ?? 0,
            trailingText: args["trailingText"] as? String)
        let staleDate = (args["staleMinutes"] as? Double).map { Date.now.addingTimeInterval($0 * 60) }
        let relevance = (args["relevanceScore"] as? Double).map { Double($0) }
        let wantsPushToken = args["wantsPushToken"] as? Bool ?? false

        do {
            let activity = try Activity.request(attributes: attrs,
                content: .init(state: state, staleDate: staleDate, relevanceScore: relevance),
                pushType: wantsPushToken ? .token : nil)
            if wantsPushToken {
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        let token = tokenData.map { String(format: "%02x", $0) }.joined()
                        pushTokenSink?(token)
                    }
                }
            }
            result(true)
        } catch {
            result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    private func handleUpdate(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String,
              let title = args["title"] as? String else { result(false); return }

        Task {
            let state = LiveActivityAttributes.ContentState(title: title,
                subtitle: args["subtitle"] as? String, progress: args["progress"] as? Double ?? 0,
                trailingText: args["trailingText"] as? String)
            let staleDate = (args["staleMinutes"] as? Double).map { Date.now.addingTimeInterval($0 * 60) }
            let relevance = (args["relevanceScore"] as? Double).map { Double($0) }
            let content = ActivityContent(state: state, staleDate: staleDate, relevanceScore: relevance)

            let alertTitle = args["alertTitle"] as? String
            let alertBody = args["alertBody"] as? String
            let playSound = args["playSound"] as? Bool ?? true
            let alertConfig: AlertConfiguration? = alertTitle != nil
                ? AlertConfiguration(title: .init(stringLiteral: alertTitle!),
                    body: alertBody != nil ? .init(stringLiteral: alertBody!) : .init(stringLiteral: ""),
                    sound: playSound ? .default : nil)
                : nil

            for activity in Activity<LiveActivityAttributes>.activities {
                if activity.attributes.id == id {
                    if let alertConfig = alertConfig {
                        await activity.update(content, alertConfiguration: alertConfig)
                    } else {
                        await activity.update(content)
                    }
                    result(true)
                    return
                }
            }
            result(false)
        }
    }

    private func handleEnd(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(false); return }
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else { result(false); return }

        Task {
            let policyStr = args["policy"] as? String ?? "immediate"
            let dismissalPolicy: ActivityUIDismissalPolicy = policyStr == "default_"
                ? .default : policyStr == "afterDuration"
                ? .after(.now + ((args["durationSeconds"] as? Double).map { $0 } ?? 3600))
                : .immediate

            for activity in Activity<LiveActivityAttributes>.activities {
                if activity.attributes.id == id {
                    await activity.end(dismissalPolicy: dismissalPolicy)
                    result(true)
                    return
                }
            }
            result(false)
        }
    }
}

@available(iOS 16.1, *)
struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String; var subtitle: String?; var progress: Double; var trailingText: String?
    }
    var id: String; var title: String; var subtitle: String?; var progress: Double; var trailingText: String?; var leadingIcon: String?
}
