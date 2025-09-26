package sncf.connect.tech.eventide

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

class EventidePlugin: FlutterPlugin, ActivityAware {
  private lateinit var binaryMessenger: BinaryMessenger
  private var permissionHandler: PermissionHandler? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    binaryMessenger = flutterPluginBinding.binaryMessenger
  }

  override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    CalendarApi.setUp(flutterPluginBinding.binaryMessenger, null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    val activity = binding.activity
    val contentResolver = activity.contentResolver
    permissionHandler = PermissionHandler(activity)
    binding.addRequestPermissionsResultListener(permissionHandler!!)
    val calendarImplem = CalendarImplem(activity, contentResolver, permissionHandler!!)
    CalendarApi.setUp(binaryMessenger, calendarImplem)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    CalendarApi.setUp(binaryMessenger, null)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    val activity = binding.activity
    val contentResolver = activity.contentResolver
    permissionHandler = PermissionHandler(activity)
    binding.addRequestPermissionsResultListener(permissionHandler!!)
    val calendarImplem = CalendarImplem(activity, contentResolver, permissionHandler!!)
    CalendarApi.setUp(binaryMessenger, calendarImplem)
  }

  override fun onDetachedFromActivity() {
    permissionHandler = null
    CalendarApi.setUp(binaryMessenger, null)
  }
}
