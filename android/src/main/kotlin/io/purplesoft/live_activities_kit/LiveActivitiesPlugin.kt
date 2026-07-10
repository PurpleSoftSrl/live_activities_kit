package io.purplesoft.live_activities_kit

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
    private lateinit var urlSchemeChannel: EventChannel
    private lateinit var activityUpdateChannel: EventChannel
    private var applicationContext: Context? = null
    private var pushTokenSink: EventChannel.EventSink? = null
    private var actionSink: EventChannel.EventSink? = null
    private var activityUpdateSink: EventChannel.EventSink? = null
    private val activeNotifications = mutableMapOf<Int, String>()

    private val notificationManager: NotificationManager? get() = applicationContext?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

    companion object { private const val NOTIFICATION_CHANNEL_ID = "live_activities_updates" }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        LiveActivitiesFlutterEngineProvider.binaryMessenger = binding.binaryMessenger
        channel = MethodChannel(binding.binaryMessenger, "live_activities_kit"); channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "live_activities_kit/pushToken"); eventChannel.setStreamHandler(this)
        actionChannel = EventChannel(binding.binaryMessenger, "live_activities_kit/actions")
        actionChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(a: Any?, e: EventChannel.EventSink?) { actionSink = e; FlutterUtils.setEventSink(e) }
            override fun onCancel(a: Any?) { actionSink = null; FlutterUtils.setEventSink(null) }
        })
        urlSchemeChannel = EventChannel(binding.binaryMessenger, "live_activities_kit/urlScheme")
        urlSchemeChannel.setStreamHandler(object : EventChannel.StreamHandler { override fun onListen(a: Any?, e: EventChannel.EventSink?) {} override fun onCancel(a: Any?) {} })
        activityUpdateChannel = EventChannel(binding.binaryMessenger, "live_activities_kit/activityUpdate")
        activityUpdateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(a: Any?, e: EventChannel.EventSink?) { activityUpdateSink = e }
            override fun onCancel(a: Any?) { activityUpdateSink = null }
        })
        createNotificationChannel()
    }

    override fun onMethodCall(call: MethodCall, result: Result) = when (call.method) {
        "isSupported" -> result.success(true)
        "areActivitiesEnabled" -> result.success(areNotificationsEnabled())
        "frequentPushesEnabled" -> result.success(true)
        "allowsPushStart" -> result.success(false)
        "requestPermission" -> { requestNotificationPermission(); result.success(true) }
        "start" -> startLiveNotification(call, result)
        "update" -> startLiveNotification(call, result)
        "end" -> endLiveNotification(call, result)
        "createOrUpdate" -> { startLiveNotification(call, result); result.success(call.argument<String>("id")) }
        "getAllIds" -> result.success(activeNotifications.values.toList())
        "getAllActivities" -> result.success(activeNotifications.entries.associate { it.value to "active" })
        "getActivityState" -> { val id = call.argument<String>("id"); result.success(if (activeNotifications.containsValue(id)) "active" else null) }
        "endAll" -> { activeNotifications.keys.forEach { notificationManager?.cancel(it) }; activeNotifications.clear(); result.success(true) }
        "getPushToken" -> result.success(null)
        else -> result.notImplemented()
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) { channel.setMethodCallHandler(null); eventChannel.setStreamHandler(null) }
    override fun onListen(a: Any?, e: EventChannel.EventSink?) { pushTokenSink = e }
    override fun onCancel(a: Any?) { pushTokenSink = null }

    private fun createNotificationChannel() { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) { notificationManager?.createNotificationChannel(NotificationChannel(NOTIFICATION_CHANNEL_ID, "Live Activities", NotificationManager.IMPORTANCE_HIGH).apply { description = "Live activity updates" }) } }

    private fun areNotificationsEnabled(): Boolean { val nm = notificationManager ?: return false; return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) nm.areNotificationsEnabled() else true }

    private fun requestNotificationPermission() { val ctx = applicationContext ?: return; if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { val nm = notificationManager ?: return; if (!nm.areNotificationsEnabled()) { ctx.startActivity(Intent().apply { action = Settings.ACTION_APP_NOTIFICATION_SETTINGS; putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName); flags = Intent.FLAG_ACTIVITY_NEW_TASK }) } } }

    private fun startLiveNotification(call: MethodCall, result: Result) {
        val ctx = applicationContext; val nm = notificationManager
        if (ctx == null || nm == null) { result.success(false); return }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !nm.areNotificationsEnabled()) { requestNotificationPermission(); result.success(false); return }
        val args = call.arguments as? Map<*, *> ?: run { result.success(false); return }
        val id = args["id"] as? String ?: run { result.success(false); return }
        val title = args["title"] as? String ?: "Update"; val subtitle = args["subtitle"] as? String
        val pd = (args["progress"] as? Number)?.toDouble() ?: 0.0; val pi = (pd * 100).toInt()
        val n = NotificationCompat.Builder(ctx, NOTIFICATION_CHANNEL_ID).setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle(title).setContentText(subtitle ?: "").setProgress(100, pi, pd == 0.0).setOngoing(true).setPriority(NotificationCompat.PRIORITY_HIGH).setCategory(NotificationCompat.CATEGORY_PROGRESS).setContentIntent(createLaunchIntent(ctx)).setStyle(NotificationCompat.BigTextStyle().bigText(subtitle).setSummaryText(title)).setUsesChronometer(pd > 0).apply { (args["color"] as? Number)?.toInt()?.let { setColor(it) }; (args["imagePath"] as? String)?.let { try { setLargeIcon(android.graphics.BitmapFactory.decodeFile(it)) } catch (_: Exception) {} } }
        val actions = args["actions"] as? List<*>; if (actions != null) for (a in actions) { val m = a as? Map<*, *> ?: continue; n.addAction(0, m["label"] as? String ?: continue, createActionIntent(ctx, m["id"] as? String ?: continue, id.hashCode())) }
        nm.notify(id.hashCode(), n.build()); activeNotifications[id.hashCode()] = id
        val removeOnKill = args["removeWhenAppIsKilled"] as? Boolean ?: false
        result.success(if (call.method == "start") id else true)
    }

    private fun endLiveNotification(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run { result.success(false); return }
        val id = args["id"] as? String ?: run { result.success(false); return }
        val policy = args["policy"] as? String ?: "immediate"
        val nid = id.hashCode(); val nm = notificationManager ?: run { result.success(false); return }; val ctx = applicationContext ?: run { result.success(false); return }
        when (policy) { "immediate" -> { nm.cancel(nid); activeNotifications.remove(nid) }; else -> { val ft = args["title"] as? String ?: "Completed"; val n = NotificationCompat.Builder(ctx, NOTIFICATION_CHANNEL_ID).setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle(ft).setContentText(args["subtitle"] as? String ?: "").setProgress(100, 100, false).setOngoing(false).setPriority(NotificationCompat.PRIORITY_LOW).setCategory(NotificationCompat.CATEGORY_STATUS).setContentIntent(createLaunchIntent(ctx)).build(); nm.notify(nid, n) } }
        result.success(true)
    }

    private fun createLaunchIntent(c: Context) = PendingIntent.getActivity(c, 0, c.packageManager.getLaunchIntentForPackage(c.packageName) ?: Intent(), if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT)
    private fun createActionIntent(c: Context, actionId: String, requestCode: Int) = PendingIntent.getBroadcast(c, requestCode, Intent("live_activities_action").apply { `package` = c.packageName; putExtra("action_id", actionId) }, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
}
