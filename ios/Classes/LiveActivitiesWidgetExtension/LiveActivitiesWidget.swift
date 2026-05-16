import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Widget Configuration

@main
struct LiveActivitiesWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            // Lock Screen / Dynamic Island expanded
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if context.attributes.leadingIcon != nil {
                        Image(systemName: context.attributes.leadingIcon!)
                            .font(.title2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.headline)
                        if let subtitle = context.state.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if let trailing = context.state.trailingText {
                        Text(trailing)
                            .font(.title3.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                if context.state.progress > 0 {
                    ProgressView(value: context.state.progress)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.2))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded - Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        if context.attributes.leadingIcon != nil {
                            Image(systemName: context.attributes.leadingIcon!)
                                .font(.title2)
                        }
                        Text(context.state.title)
                            .font(.headline)
                    }
                }
                // Expanded - Trailing  
                DynamicIslandExpandedRegion(.trailing) {
                    if let trailing = context.state.trailingText {
                        Text(trailing)
                            .font(.title3.monospacedDigit())
                    }
                }
                // Expanded - Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.progress > 0 {
                        ProgressView(value: context.state.progress)
                    }
                    if let subtitle = context.state.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                // Compact leading (icon)
                Image(systemName: context.attributes.leadingIcon ?? "clock")
                    .font(.caption)
            } compactTrailing: {
                // Compact trailing (progress)
                if context.state.progress > 0 {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let trailing = context.state.trailingText {
                    Text(trailing)
                        .font(.caption2)
                }
            } minimal: {
                // Minimal (smallest icon-only)
                Image(systemName: context.attributes.leadingIcon ?? "clock")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview

struct LiveActivitiesWidget_Previews: PreviewProvider {
    static let attributes = LiveActivityAttributes(
        id: "preview",
        title: "Order #123",
        subtitle: "Preparing",
        progress: 0.3,
        trailingText: "5 min",
        leadingIcon: "bag.fill"
    )
    static let contentState = LiveActivityAttributes.ContentState(
        title: "Order #123",
        subtitle: "Preparing your items",
        progress: 0.3,
        trailingText: "5 min"
    )

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Lock Screen")
    }
}
