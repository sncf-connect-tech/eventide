package sncf.connect.tech.flutter_calendar_connect

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

/** CalendarPlugin */
class CalendarPlugin: FlutterPlugin, ActivityAware {
  lateinit var binaryMessenger: BinaryMessenger

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    binaryMessenger = flutterPluginBinding.binaryMessenger
  }

  override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    CalendarApi.setUp(flutterPluginBinding.binaryMessenger, null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    val activity = binding.activity
    val contentResolver = activity.contentResolver
    val permissionHandler = PermissionHandler(activity)
    val calendarImplem = CalendarImplem(contentResolver, permissionHandler)
    CalendarApi.setUp(binaryMessenger, calendarImplem)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    CalendarApi.setUp(binaryMessenger, null)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    val activity = binding.activity
    val contentResolver = activity.contentResolver
    val permissionHandler = PermissionHandler(activity)
    val calendarImplem = CalendarImplem(contentResolver, permissionHandler)
    CalendarApi.setUp(binaryMessenger, calendarImplem)
  }

  override fun onDetachedFromActivity() {
    CalendarApi.setUp(binaryMessenger, null)
  }
}
