package sncf.connect.tech.eventide

import android.accounts.AccountManager
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

class EventidePlugin: FlutterPlugin, ActivityAware {
    private lateinit var binaryMessenger: BinaryMessenger
    private var permissionHandler: PermissionHandler? = null
    private var activityManager: CalendarActivityManager? = null
    private var accountManager: AccountManager? = null
    private var packageManager: PackageManager? = null

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
        activityManager = CalendarActivityManager(activity)
        accountManager = AccountManager.get(activity)
        packageManager = activity.packageManager

        binding.addRequestPermissionsResultListener(permissionHandler!!)

        val calendarImplem = CalendarImplem(contentResolver, permissionHandler!!, activityManager!!, accountManager!!, packageManager!!)
        CalendarApi.setUp(binaryMessenger, calendarImplem)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        CalendarApi.setUp(binaryMessenger, null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        val activity = binding.activity
        val contentResolver = activity.contentResolver

        permissionHandler = PermissionHandler(activity)
        activityManager = CalendarActivityManager(activity)
        accountManager = AccountManager.get(activity)

        binding.addRequestPermissionsResultListener(permissionHandler!!)

        val calendarImplem = CalendarImplem(contentResolver, permissionHandler!!, activityManager!!, accountManager!!, packageManager!!)
        CalendarApi.setUp(binaryMessenger, calendarImplem)
    }

    override fun onDetachedFromActivity() {
        permissionHandler = null
        activityManager = null
        accountManager = null
        packageManager = null
        CalendarApi.setUp(binaryMessenger, null)
    }
}
