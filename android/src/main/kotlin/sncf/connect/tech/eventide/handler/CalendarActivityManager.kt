package sncf.connect.tech.eventide.handler

import android.app.Activity
import android.app.Application
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import java.io.File

class CalendarActivityManager(): Application.ActivityLifecycleCallbacks {
    var activity: Activity? = null
    private var shareIntentCallback: ((Unit) -> Unit)? = null
    private var isWaitingForReturn = false

    fun createShareIntent(icsContent: String, callback: (Unit) -> Unit) {
        withActivity { activity ->
            val file = File(activity.cacheDir, "eventide.ics")
            file.writeText(icsContent)

            val authority = "${activity.packageName}.eventide.fileprovider"
            val contentUri: Uri = FileProvider.getUriForFile(
                activity,
                authority,
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(contentUri, "text/calendar")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT)
            }

            shareIntentCallback = callback
            isWaitingForReturn = true

            activity.startActivity(intent)
        }
    }

    // Called when user comes back to the app
    override fun onActivityResumed(activity: Activity) {
        if (isWaitingForReturn && activity === this.activity) {
            isWaitingForReturn = false
            shareIntentCallback?.invoke(Unit)
            shareIntentCallback = null
        }
    }

    private fun withActivity(block: (Activity) -> Unit) {
        activity?.let { block(it) }
            ?: throw IllegalStateException("ActivityPluginBinding is not correctly set.")
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
}
