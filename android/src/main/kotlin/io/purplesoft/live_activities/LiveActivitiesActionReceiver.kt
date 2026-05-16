package io.purplesoft.live_activities

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class LiveActivitiesActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        val actionId = intent.getStringExtra("action_id") ?: return

        // Forward to Flutter via EventChannel stored in the plugin
        val messenger = LiveActivitiesFlutterEngineProvider.binaryMessenger
        if (messenger != null) {
            val channel = EventChannel(messenger, "live_activities/actions")
            // Re-broadcast via the same stream
            FlutterUtils.postEvent(actionId)
        }
    }
}

object FlutterUtils {
    private var lastEventSink: EventChannel.EventSink? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        lastEventSink = sink
    }

    fun postEvent(event: String) {
        lastEventSink?.success(event)
    }
}

object LiveActivitiesFlutterEngineProvider {
    var binaryMessenger: io.flutter.plugin.common.BinaryMessenger? = null
}
