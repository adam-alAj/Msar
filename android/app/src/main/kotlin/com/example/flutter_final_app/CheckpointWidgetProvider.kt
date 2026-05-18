package com.example.flutter_final_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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

        private fun enqueueImmediateWork(context: Context) {
            try {
                val request = OneTimeWorkRequestBuilder<CheckpointWidgetWorker>()
                    .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                    .build()
                WorkManager.getInstance(context).enqueue(request)
            } catch (_: Exception) {}
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, id)
            } catch (_: Exception) {
                // Show a safe fallback so the widget doesn't display "Can't load widget"
                try {
                    val fallback = RemoteViews(context.packageName, R.layout.widget_checkpoint)
                    fallback.setViewVisibility(R.id.empty_state, View.VISIBLE)
                    fallback.setTextViewText(R.id.empty_state, "اضغط ↻ لتحديث الحواجز القريبة")
                    appWidgetManager.updateAppWidget(id, fallback)
                } catch (_: Exception) {}
            }
        }

        // If no cached data exists, trigger an immediate fetch
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val dataJson = prefs.getString(KEY_WIDGET_DATA, null)
            if (dataJson.isNullOrEmpty()) {
                enqueueImmediateWork(context)
            }
        } catch (_: Exception) {}
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            enqueueImmediateWork(context)
        }
    }

    override fun onEnabled(context: Context) {
        try {
            // Schedule periodic background updates
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
        } catch (_: Exception) {}

        // Also trigger an immediate one-time fetch so widget populates right away
        enqueueImmediateWork(context)
    }

    override fun onDisabled(context: Context) {
        try {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        } catch (_: Exception) {}
    }

    private fun updateWidget(context: Context, mgr: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_checkpoint)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Refresh button intent
        val refreshIntent = Intent(context, CheckpointWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPending = PendingIntent.getBroadcast(
            context, 0, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try { views.setOnClickPendingIntent(R.id.widget_refresh, refreshPending) } catch (_: Exception) {}

        // Last update timestamp
        val lastUpdate = prefs.getLong(KEY_LAST_UPDATE, 0L)
        if (lastUpdate > 0) {
            val minutesAgo = (System.currentTimeMillis() - lastUpdate) / 60000
            views.setTextViewText(R.id.widget_timestamp, "منذ ${minutesAgo} د")
        } else {
            views.setTextViewText(R.id.widget_timestamp, "")
        }

        // Load checkpoint data from SharedPreferences (JSON array)
        val dataJson = prefs.getString(KEY_WIDGET_DATA, null)
        val rowIds = arrayOf(
            Triple(R.id.row1, R.id.name1, R.id.distance1),
            Triple(R.id.row2, R.id.name2, R.id.distance2),
            Triple(R.id.row3, R.id.name3, R.id.distance3),
        )
        val statusIds = arrayOf(R.id.status1, R.id.status2, R.id.status3)
        val statusTextIds = arrayOf(R.id.status_text1, R.id.status_text2, R.id.status_text3)

        if (dataJson.isNullOrEmpty()) {
            // Empty state — hide rows, show prompt
            for ((rowId, _, _) in rowIds) views.setViewVisibility(rowId, View.GONE)
            views.setViewVisibility(R.id.empty_state, View.VISIBLE)
            try { views.setOnClickPendingIntent(R.id.empty_state, refreshPending) } catch (_: Exception) {}
        } else {
            views.setViewVisibility(R.id.empty_state, View.GONE)
            try {
                val checkpoints = JSONArray(dataJson)
                for (i in rowIds.indices) {
                    val (rowId, nameId, distId) = rowIds[i]
                    if (i < checkpoints.length()) {
                        val cp = checkpoints.getJSONObject(i)
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(nameId, cp.optString("name", ""))
                        views.setTextViewText(distId, cp.optString("distance", ""))

                        // Status color
                        val statusStr = cp.optString("status", "OPEN")
                        val statusColor = when (statusStr) {
                            "CLOSED"  -> 0xFFE53935.toInt()
                            "CROWDED" -> 0xFFFFA726.toInt()
                            else      -> 0xFF4CAF50.toInt()
                        }
                        val statusLabel = when (statusStr) {
                            "CLOSED"  -> "مغلق"
                            "CROWDED" -> "أزمة"
                            else      -> "سالك"
                        }
                        try {
                            views.setInt(statusIds[i], "setColorFilter", statusColor)
                        } catch (_: Exception) {}
                        views.setTextViewText(statusTextIds[i], statusLabel)
                        views.setTextColor(statusTextIds[i], statusColor)

                        // Tap row → launch app
                        try {
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
                        } catch (_: Exception) {}
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }
            } catch (_: Exception) {
                // JSON parse error → fall back to empty state
                for ((rowId, _, _) in rowIds) views.setViewVisibility(rowId, View.GONE)
                views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                try { views.setOnClickPendingIntent(R.id.empty_state, refreshPending) } catch (_: Exception) {}
            }
        }

        mgr.updateAppWidget(widgetId, views)
    }
}
