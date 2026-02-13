package sncf.connect.tech.eventide

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.content.ContextCompat.startActivity

class CalendarActivityManager(private val context: Context) {

    fun startCreateEventActivity(
        eventContentUri: Uri,
        title: String? = null,
        startDate: Long? = null,
        endDate: Long? = null,
        isAllDay: Boolean?,
        description: String? = null,
        location: String? = null,
    ) {
        val intent = Intent(Intent.ACTION_INSERT)
        intent.setDataAndType(eventContentUri, "vnd.android.cursor.dir/event")
        intent.putExtra(CalendarContract.Events.TITLE, title)
        intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startDate)
        intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endDate)
        intent.putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, isAllDay)
        intent.putExtra(CalendarContract.Events.EVENT_LOCATION, location)
        intent.putExtra(CalendarContract.Events.DESCRIPTION, description)
        intent.putExtra(CalendarContract.Events.EVENT_TIMEZONE, "UTC")

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        startActivity(context, intent, null)
    }
}
