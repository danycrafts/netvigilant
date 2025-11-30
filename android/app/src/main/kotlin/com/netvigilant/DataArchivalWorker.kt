package com.netvigilant

import android.content.Context
import android.os.Build
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit
import android.util.Log
import java.io.File
import java.io.IOException
import com.google.gson.Gson

class DataArchivalWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        const val UNIQUE_WORK_NAME = "DataArchivalWorker"
        private const val MAX_RETRIES = 3
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        if (runAttemptCount > MAX_RETRIES) {
            Log.w("DataArchivalWorker", "Work failed after $MAX_RETRIES attempts.")
            return@withContext Result.failure()
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val networkDataSource = AndroidNetworkDataSource(applicationContext)
                val endTime = System.currentTimeMillis()
                val startTime = endTime - TimeUnit.DAYS.toMillis(1)

                val networkUsage = networkDataSource.getHistoricalNetworkUsage(startTime, endTime)

                if (networkUsage.isNotEmpty()) {
                    // In a real-world scenario, this data would be saved to a persistent
                    // database like Room or SQLite.
                    Log.d("DataArchivalWorker", "Successfully fetched " + networkUsage.size + " network usage records.")
                    saveDataToDatabase(networkUsage)
                } else {
                    Log.i("DataArchivalWorker", "No network usage data to archive. Retrying later.")
                    return@withContext Result.retry()
                }
            }
            Result.success()
        } catch (e: Exception) {
            Log.e("DataArchivalWorker", "Error fetching network usage data: " + e.message)
            if (runAttemptCount < MAX_RETRIES) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    private fun saveDataToDatabase(networkUsage: List<Map<String, Any>>) {
        val gson = Gson()
        val jsonString = gson.toJson(networkUsage)

        try {
            val file = File(applicationContext.filesDir, "network_usage_log.json")
            file.appendText(jsonString + "\n")
            Log.d("DataArchivalWorker", "Successfully saved " + networkUsage.size + " records to " + file.absolutePath)
        } catch (e: IOException) {
            Log.e("DataArchivalWorker", "Error saving data to file: " + e.message)
        }
    }
}
