package sncf.connect.tech.eventide

import android.app.Application
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

class EventidePlugin: FlutterPlugin, ActivityAware {
    interface ActivityComponent {
        val requestPermissionsResultListener: PluginRegistry.RequestPermissionsResultListener
        val calendarActivityLifecycleListener: Application.ActivityLifecycleCallbacks
        fun updateActivity(binding: ActivityPluginBinding?)
    }

    private lateinit var activityComponent: ActivityComponent
    private var binding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val calendarImpl = CalendarImplem(flutterPluginBinding.applicationContext)
        CalendarApi.setUp(flutterPluginBinding.binaryMessenger, calendarImpl)
        activityComponent = calendarImpl
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        CalendarApi.setUp(flutterPluginBinding.binaryMessenger, null)
    }

    private fun attachToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        activityComponent.updateActivity(binding)
        binding.addRequestPermissionsResultListener(activityComponent.requestPermissionsResultListener)
        binding.activity.application.registerActivityLifecycleCallbacks(activityComponent.calendarActivityLifecycleListener)
    }

    private fun detachFromActivity() {
        binding?.removeRequestPermissionsResultListener(activityComponent.requestPermissionsResultListener)
        binding?.activity?.application?.unregisterActivityLifecycleCallbacks(activityComponent.calendarActivityLifecycleListener)
        activityComponent.updateActivity(null)
        binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attachToActivity(binding)
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attachToActivity(binding)
    override fun onDetachedFromActivityForConfigChanges() = detachFromActivity()
    override fun onDetachedFromActivity() = detachFromActivity()
}
