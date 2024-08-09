package sncf.connect.tech.flutter_calendar_connect

import CalendarActions
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

/** CalendarPlugin */
class CalendarPlugin: FlutterPlugin, ActivityAware {
  private lateinit var binaryMessenger: BinaryMessenger

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    binaryMessenger = flutterPluginBinding.binaryMessenger
  }

  override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    CalendarActions.setUp(flutterPluginBinding.binaryMessenger, null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    CalendarActions.setUp(binaryMessenger, CalendarApi(binding.activity))
  }

  override fun onDetachedFromActivityForConfigChanges() {
    CalendarActions.setUp(binaryMessenger, null)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    CalendarActions.setUp(binaryMessenger, CalendarApi(binding.activity))
  }

  override fun onDetachedFromActivity() {
    CalendarActions.setUp(binaryMessenger, null)
  }
}
