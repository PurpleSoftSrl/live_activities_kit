package io.purplesoft.live_activities

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LiveActivitiesPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var actionChannel: EventChannel
    private var applicationContext: Context? = null
    private var pushTokenSink: EventChannel.EventSink? = null
    private var actionSink: EventChannel.EventSink? = null

    private val notificationManager: NotificationManager?
        get() = applicationContext?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "live_activities_updates"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        LiveActivitiesFlutterEngineProvider.binaryMessenger = flutterPluginBinding.binaryMessenger
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "live_activities")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "live_activities/pushToken")
        eventChannel.setStreamHandler(this)
        actionChannel = EventChannel(flutterPluginBinding.binaryMessenger, "live_activities/actions")
        actionChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                actionSink = events
                FlutterUtils.setEventSink(events)
            }
            override fun onCancel(arguments: Any?) {
                actionSink = null
                FlutterUtils.setEventSink(null)
            }
        })
        createNotificationChannel()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isSupported" -> result.success(true)
            "frequentPushesEnabled" -> result.success(true)
            "start" -> startLiveNotification(call, result)
            "update" -> startLiveNotification(call, result)
            "end" -> endLiveNotification(call, result)
            "getPushToken" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        pushTokenSink = events
    }

    override fun onCancel(arguments: Any?) {
        pushTokenSink = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID, "Live Activities", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Live activity updates" }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun startLiveNotification(call: MethodCall, result: Result) {
        val ctx = applicationContext
        val nm = notificationManager
        if (ctx == null || nm == null) {
            Log.e("LiveActivities", "No context or notification manager")
            result.success(false)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!nm.areNotificationsEnabled()) {
                Log.w("LiveActivities", "Opening notification settings")
                val intent = Intent().apply {
                    action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                    putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                ctx.startActivity(intent)
                result.success(false)
                return
            }
        }

        val args = call.arguments as? Map<*, *> ?: run { result.success(false); return }
        val id = args["id"] as? String ?: run { result.success(false); return }
        val title = args["title"] as? String ?: "Update"
        val subtitle = args["subtitle"] as? String
        val progressDart = (args["progress"] as? Number)?.toDouble() ?: 0.0
        val progressInt = (progressDart * 100).toInt()

        val notification = NotificationCompat.Builder(ctx, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(subtitle ?: "")
            .setProgress(100, progressInt, progressDart == 0.0)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(createLaunchIntent(ctx))
            .setStyle(NotificationCompat.BigTextStyle().bigText(subtitle).setSummaryText(title))
            .setUsesChronometer(progressDart > 0)
            .apply {
                (args["color"] as? Number)?.toInt()?.let { setColor(it) }
            }

        // Add action buttons
        val actionList = args["actions"] as? List<*>
        if (actionList != null) {
            for (action in actionList) {
                val map = action as? Map<*, *> ?: continue
                val actionId = map["id"] as? String ?: continue
                val label = map["label"] as? String ?: continue
                val pi = createActionIntent(ctx, actionId, id.hashCode())
                notification.addAction(0, label, pi)
            }
        }

        nm.notify(id.hashCode(), notification.build())
        result.success(true)
    }

    private fun endLiveNotification(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run { result.success(false); return }
        val id = args["id"] as? String ?: run { result.success(false); return }
        val policy = args["policy"] as? String ?: "immediate"

        val nm = notificationManager ?: run { result.success(false); return }
        val ctx = applicationContext ?: run { result.success(false); return }
        val notificationId = id.hashCode()

        when (policy) {
            "immediate" -> nm.cancel(notificationId)
            "default_", "afterDuration" -> {
                // Update notification to show final state with completed progress
                val finalTitle = args["title"] as? String ?: "Completed"
                val finalSubtitle = args["subtitle"] as? String
                val notification = NotificationCompat.Builder(ctx, NOTIFICATION_CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle(finalTitle)
                    .setContentText(finalSubtitle ?: "")
                    .setProgress(100, 100, false)
                    .setOngoing(false)
                    .setPriority(NotificationCompat.PRIORITY_LOW)
                    .setCategory(NotificationCompat.CATEGORY_STATUS)
                    .setContentIntent(createLaunchIntent(ctx))
                    .build()
                nm.notify(notificationId, notification)
            }
        }
        result.success(true)
    }

    private fun createLaunchIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
        return PendingIntent.getActivity(
            context, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
    }

    private fun createActionIntent(context: Context, actionId: String, requestCode: Int): PendingIntent {
        val intent = Intent("live_activities_action").apply {
            `package` = context.packageName
            putExtra("action_id", actionId)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}
