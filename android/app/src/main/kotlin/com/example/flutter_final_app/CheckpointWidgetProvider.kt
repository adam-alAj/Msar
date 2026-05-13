package com.example.flutter_final_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.widget.RemoteViews
import androidx.work.*
import org.json.JSONArray
import java.util.concurrent.TimeUnit

class CheckpointWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.example.flutter_final_app.WIDGET_REFRESH"
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_WIDGET_DATA = "flutter.widget_checkpoints"
        const val KEY_LAST_UPDATE = "flutter.widget_last_update"
        const val WORK_NAME = "msar_widget_update"

        fun triggerUpdate(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, CheckpointWidgetProvider::class.java))
            val intent = Intent(context, CheckpointWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            // Enqueue one-time immediate work
            val request = OneTimeWorkRequestBuilder<CheckpointWidgetWorker>()
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()
            WorkManager.getInstance(context).enqueue(request)
        }
    }

    override fun onEnabled(context: Context) {
        // Schedule periodic background updates when first widget is placed
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()

        val periodicWork = PeriodicWorkRequestBuilder<CheckpointWidgetWorker>(15, TimeUnit.MINUTES)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            periodicWork
        )
    }

    override fun onDisabled(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }

    private fun updateWidget(context: Context, mgr: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_checkpoint)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Refresh button intent
        val refreshIntent = Intent(context, CheckpointWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPending = PendingIntent.getBroadcast(
            context, 0, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_refresh, refreshPending)

        // Last update timestamp
        val lastUpdate = prefs.getLong(KEY_LAST_UPDATE, 0L)
        if (lastUpdate > 0) {
            val minutesAgo = (System.currentTimeMillis() - lastUpdate) / 60000
            views.setTextViewText(R.id.widget_timestamp, "منذ ${minutesAgo} د")
        }

        // Load checkpoint data from SharedPreferences (JSON array)
        val dataJson = prefs.getString(KEY_WIDGET_DATA, null)
        val rowIds = arrayOf(
            Triple(R.id.row1, R.id.name1, R.id.distance1),
            Triple(R.id.row2, R.id.name2, R.id.distance2),
            Triple(R.id.row3, R.id.name3, R.id.distance3),
        )

        if (dataJson.isNullOrEmpty()) {
            // Empty state
            for ((rowId, _, _) in rowIds) views.setViewVisibility(rowId, View.GONE)
            views.setViewVisibility(R.id.empty_state, View.VISIBLE)
            // Tap empty state to refresh
            views.setOnClickPendingIntent(R.id.empty_state, refreshPending)
        } else {
            views.setViewVisibility(R.id.empty_state, View.GONE)
            val checkpoints = JSONArray(dataJson)
            for (i in rowIds.indices) {
                val (rowId, nameId, distId) = rowIds[i]
                if (i < checkpoints.length()) {
                    val cp = checkpoints.getJSONObject(i)
                    views.setViewVisibility(rowId, View.VISIBLE)
                    views.setTextViewText(nameId, cp.getString("name"))
                    views.setTextViewText(distId, cp.getString("distance"))

                    // Status color via tint
                    val statusColor = when (cp.optString("status", "OPEN")) {
                        "CLOSED" -> 0xFFE53935.toInt()
                        "CROWDED" -> 0xFFFFA726.toInt()
                        else -> 0xFF4CAF50.toInt()
                    }
                    views.setInt(rowIds[i].first.let {
                        // Set status circle color - use the status view ID
                        when (i) {
                            0 -> R.id.status1
                            1 -> R.id.status2
                            else -> R.id.status3
                        }
                    }, "setColorFilter", statusColor)

                    // Tap row → launch app with checkpoint coordinates
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("checkpoint_lat", cp.optDouble("lat", 0.0))
                        putExtra("checkpoint_lng", cp.optDouble("lng", 0.0))
                        putExtra("checkpoint_id", cp.optString("id", ""))
                    }
                    val launchPending = PendingIntent.getActivity(
                        context, i + 100, launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(rowId, launchPending)
                } else {
                    views.setViewVisibility(rowId, View.GONE)
                }
            }
        }

        mgr.updateAppWidget(widgetId, views)
    }
}
