package com.example.flutter_final_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.*

class CheckpointWidgetWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_WIDGET_DATA = "flutter.widget_checkpoints"
        private const val KEY_LAST_UPDATE = "flutter.widget_last_update"
        private const val KEY_LAST_LAT = "flutter.widget_last_lat"
        private const val KEY_LAST_LNG = "flutter.widget_last_lng"
        // Ramallah center as fallback
        private const val DEFAULT_LAT = 31.9038
        private const val DEFAULT_LNG = 35.2034
    }

    override suspend fun doWork(): Result {
        return try {
            val location = getLocation()
            val lat = location?.latitude ?: getFallbackLat()
            val lng = location?.longitude ?: getFallbackLng()

            // Save last known position
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putFloat(KEY_LAST_LAT, lat.toFloat()).putFloat(KEY_LAST_LNG, lng.toFloat()).apply()

            // Fetch checkpoints from Firestore
            val db = FirebaseFirestore.getInstance()
            val snapshot = db.collection("checkpoints").get().await()

            data class CpData(val id: String, val name: String, val lat: Double, val lng: Double, val region: String, val dist: Double)

            val checkpoints = snapshot.documents.mapNotNull { doc ->
                val data = doc.data ?: return@mapNotNull null
                val cpLat = (data["latitude"] as? Number)?.toDouble() ?: return@mapNotNull null
                val cpLng = (data["longitude"] as? Number)?.toDouble() ?: return@mapNotNull null
                val name = data["name"] as? String ?: return@mapNotNull null
                val region = data["region"] as? String ?: ""
                val dist = haversineKm(lat, lng, cpLat, cpLng)
                CpData(doc.id, name, cpLat, cpLng, region, dist)
            }.filter { it.dist <= 50.0 } // Within 50km
                .sortedBy { it.dist }
                .take(3)

            // Get statuses for nearest checkpoints
            val cutoff = com.google.firebase.Timestamp.now().toDate().time - (60 * 60 * 1000) // 1 hour
            val votesSnapshot = db.collection("votes").get().await()

            val votesByCheckpoint = mutableMapOf<String, MutableList<String>>()
            for (vDoc in votesSnapshot.documents) {
                val vData = vDoc.data ?: continue
                val cpId = vData["checkpointId"] as? String ?: continue
                val ts = (vData["timestamp"] as? com.google.firebase.Timestamp)?.toDate()?.time ?: continue
                if (ts < cutoff) continue
                val status = vData["status"] as? String ?: continue
                votesByCheckpoint.getOrPut(cpId) { mutableListOf() }.add(status)
            }

            // Build JSON array for widget
            val jsonArray = JSONArray()
            for (cp in checkpoints) {
                val obj = JSONObject()
                obj.put("id", cp.id)
                obj.put("name", cp.name)
                obj.put("lat", cp.lat)
                obj.put("lng", cp.lng)
                obj.put("distance", formatDistance(cp.dist))

                // Determine dominant status
                val votes = votesByCheckpoint[cp.id] ?: emptyList()
                val status = if (votes.isEmpty()) "OPEN" else {
                    votes.groupingBy { it }.eachCount().maxByOrNull { it.value }?.key ?: "OPEN"
                }
                obj.put("status", status)
                jsonArray.put(obj)
            }

            prefs.edit()
                .putString(KEY_WIDGET_DATA, jsonArray.toString())
                .putLong(KEY_LAST_UPDATE, System.currentTimeMillis())
                .apply()

            // Trigger widget UI update
            CheckpointWidgetProvider.triggerUpdate(context)

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private suspend fun getLocation(): Location? {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) return null

        return try {
            val client = LocationServices.getFusedLocationProviderClient(context)
            val cts = CancellationTokenSource()
            client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, cts.token).await()
        } catch (_: Exception) {
            null
        }
    }

    private fun getFallbackLat(): Double {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getFloat(KEY_LAST_LAT, DEFAULT_LAT.toFloat()).toDouble()
    }

    private fun getFallbackLng(): Double {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getFloat(KEY_LAST_LNG, DEFAULT_LNG.toFloat()).toDouble()
    }

    private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val R = 6371.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2).pow(2) + cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) * sin(dLon / 2).pow(2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private fun formatDistance(km: Double): String {
        return if (km < 1.0) "${(km * 1000).toInt()} م" else "${"%.1f".format(km)} كم"
    }
}
