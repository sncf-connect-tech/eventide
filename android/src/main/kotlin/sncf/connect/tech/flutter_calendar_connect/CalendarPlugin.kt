package sncf.connect.tech.flutter_calendar_connect

import CalendarActions
import android.content.Context
import androidx.activity.result.ActivityResultLauncher
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** CalendarPlugin */
class CalendarPlugin: FlutterPlugin, ActivityAware {
  private lateinit var _context: Context
  private var _calendarDelegate: CalendarDelegate? = null
  private lateinit var launcher: ActivityResultLauncher<Boolean>

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    _context = flutterPluginBinding.applicationContext
    CalendarActions.setUp(flutterPluginBinding.binaryMessenger, _calendarDelegate)
  }

  override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    CalendarActions.setUp(flutterPluginBinding.binaryMessenger, null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    _calendarDelegate = CalendarDelegate(binding, _context)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    _calendarDelegate = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    _calendarDelegate = CalendarDelegate(binding, _context)
  }

  override fun onDetachedFromActivity() {
    _calendarDelegate = null
  }
}
