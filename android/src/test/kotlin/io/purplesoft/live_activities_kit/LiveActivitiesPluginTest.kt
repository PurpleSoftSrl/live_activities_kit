package io.purplesoft.live_activities_kit

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * Unit tests for the Kotlin portion of the plugin. These exercise the method
 * channel handler directly without a running Flutter engine, so they only cover
 * methods that don't touch platform services.
 *
 * Run with `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * from an IDE that supports JUnit such as Android Studio.
 */
internal class LiveActivitiesPluginTest {
    @Test
    fun onMethodCall_isSupported_returnsTrue() {
        val plugin = LiveActivitiesPlugin()

        val call = MethodCall("isSupported", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(true)
    }

    @Test
    fun onMethodCall_unknownMethod_notImplemented() {
        val plugin = LiveActivitiesPlugin()

        val call = MethodCall("someUnknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }
}
