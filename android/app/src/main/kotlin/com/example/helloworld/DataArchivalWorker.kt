package com.example.netvigilant

import android.content.Context
import android.app.usage.UsageStatsManager
import android.content.pm.PackageManager
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.ListenableWorker
import androidx.work.Data
import com.netvigilant.AndroidNetworkDataSource
import com.netvigilant.SystemMetricsManager
import com.netvigilant.PermissionManager
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.json.JSONObject
import org.json.JSONArray
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

/**
 * Comprehensive data archival worker with multithreading and database integration
 * Handles data aggregation, storage, cleanup, and error recovery
 */
class DataArchivalWorker(appContext: Context, workerParams: WorkerParameters) : CoroutineWorker(appContext, workerParams) {
    
    companion object {
        private const val TAG = "DataArchivalWorker"
        private const val DATA_DIR = "netvigilant_data"
        private const val MAX_RETRY_ATTEMPTS = 3
        private const val ARCHIVAL_PERIOD_HOURS = 1
        private const val DATA_RETENTION_DAYS = 30
    }
    
    private val systemMetricsManager by lazy { SystemMetricsManager(applicationContext) }
    private val androidNetworkDataSource by lazy { AndroidNetworkDataSource(applicationContext) }
    private val permissionManager by lazy { PermissionManager(applicationContext) }
    
    // Thread pool for concurrent operations
    private val executor = Executors.newFixedThreadPool(4)
    private val dataCache = ConcurrentHashMap<String, Any>()
    
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        Log.i(TAG, "Starting comprehensive data archival task...")
        
        val startTime = System.currentTimeMillis()
        var retryCount = 0
        var lastError: Exception? = null
        
        // Retry mechanism with exponential backoff
        while (retryCount < MAX_RETRY_ATTEMPTS) {
            try {
                val result = executeDataArchival()
                
                Log.i(TAG, "Data archival completed successfully in ${System.currentTimeMillis() - startTime}ms")
                return@withContext result
                
            } catch (e: Exception) {
                lastError = e
                retryCount++
                Log.w(TAG, "Data archival attempt $retryCount failed: ${e.message}")
                
                if (retryCount < MAX_RETRY_ATTEMPTS) {
                    val delayMs = (1000 * Math.pow(2.0, retryCount.toDouble())).toLong()
                    Log.i(TAG, "Retrying in ${delayMs}ms...")
                    delay(delayMs)
                } else {
                    Log.e(TAG, "Data archival failed after $MAX_RETRY_ATTEMPTS attempts", e)
                    return@withContext Result.failure(
                        Data.Builder()
                            .putString("error", e.message ?: "Unknown error")
                            .putInt("retryCount", retryCount)
                            .build()
                    )
                }
            }
        }
        
        Result.failure()
    }
    
    /**
     * Execute the main data archival process with concurrent operations
     */
    private suspend fun executeDataArchival(): Result = coroutineScope {
        Log.i(TAG, "Executing data archival with concurrent operations...")
        
        // Check permissions first
        if (!permissionManager.hasUsageStatsPermission()) {
            Log.w(TAG, "Usage stats permission not granted, skipping archival")
            return@coroutineScope Result.success(
                Data.Builder()
                    .putString("status", "skipped_no_permission")
                    .build()
            )
        }
        
        val currentTime = System.currentTimeMillis()
        val archivalStartTime = currentTime - TimeUnit.HOURS.toMillis(ARCHIVAL_PERIOD_HOURS.toLong())
        
        // Start metrics monitoring
        systemMetricsManager.startMonitoring()
        
        try {
            // Execute data collection concurrently
            val appUsageDeferred = async { collectAppUsageData(archivalStartTime, currentTime) }
            val networkUsageDeferred = async { collectNetworkUsageData(archivalStartTime, currentTime) }
            val systemMetricsDeferred = async { collectSystemMetricsData() }
            
            // Wait for all data collection to complete
            val appUsageData = appUsageDeferred.await()
            val networkUsageData = networkUsageDeferred.await()
            val systemMetricsData = systemMetricsDeferred.await()
            
            Log.i(TAG, "Data collection completed - Apps: ${appUsageData.size}, Network: ${networkUsageData.size}, Metrics: ${systemMetricsData.size}")
            
            // Process and store data concurrently
            val processingJobs = listOf(
                async { processAndStoreAppData(appUsageData, archivalStartTime) },
                async { processAndStoreNetworkData(networkUsageData, archivalStartTime) },
                async { processAndStoreMetricsData(systemMetricsData, archivalStartTime) },
                async { generateHourlySummary(archivalStartTime) },
                async { performDataCleanup() }
            )
            
            // Wait for all processing to complete
            processingJobs.awaitAll()
            
            Log.i(TAG, "Data archival processing completed successfully")
            
            Result.success(
                Data.Builder()
                    .putString("status", "success")
                    .putLong("archivalTime", archivalStartTime)
                    .putInt("appsProcessed", appUsageData.size)
                    .putInt("networkRecords", networkUsageData.size)
                    .putLong("processingTimeMs", System.currentTimeMillis() - currentTime)
                    .build()
            )
            
        } finally {
            systemMetricsManager.stopMonitoring()
        }
    }
    
    /**
     * Collect app usage data with real system metrics
     */
    private suspend fun collectAppUsageData(startTime: Long, endTime: Long): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        try {
            val usageStatsManager = applicationContext.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val packageManager = applicationContext.packageManager
            
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                startTime,
                endTime
            ).filter { it.totalTimeInForeground > 0 }
            
            val packageNames = usageStats.map { it.packageName }
            val realMetrics = systemMetricsManager.getAppUsageWithMetrics(packageNames)
            
            usageStats.mapNotNull { stats ->
                try {
                    val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val metrics = realMetrics[stats.packageName]
                    
                    mapOf(
                        "packageName" to stats.packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to stats.totalTimeInForeground,
                        "lastTimeUsed" to stats.lastTimeUsed,
                        "firstTimeStamp" to stats.firstTimeStamp,
                        "cpuUsage" to (metrics?.get("cpuUsage") ?: 0.0),
                        "memoryUsage" to (metrics?.get("memoryUsage") ?: 0.0),
                        "batteryUsage" to (metrics?.get("batteryUsage") ?: 0.0),
                        "timestamp" to System.currentTimeMillis()
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "Error processing app ${stats.packageName}: ${e.message}")
                    null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error collecting app usage data", e)
            emptyList()
        }
    }
    
    /**
     * Collect network usage data concurrently
     */
    private suspend fun collectNetworkUsageData(startTime: Long, endTime: Long): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        try {
            val networkData = androidNetworkDataSource.getHistoricalNetworkUsage(startTime, endTime)
            
            networkData.map { data ->
                data.toMutableMap().apply {
                    put("timestamp", System.currentTimeMillis())
                    put("archivalPeriod", endTime - startTime)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error collecting network usage data", e)
            emptyList()
        }
    }
    
    /**
     * Collect current system metrics
     */
    private suspend fun collectSystemMetricsData(): Map<String, Map<String, Double>> = withContext(Dispatchers.Default) {
        try {
            systemMetricsManager.getAllCachedMetrics()
        } catch (e: Exception) {
            Log.e(TAG, "Error collecting system metrics", e)
            emptyMap()
        }
    }
    
    /**
     * Process and store app data with efficient file I/O
     */
    private suspend fun processAndStoreAppData(
        appData: List<Map<String, Any>>,
        archivalTime: Long
    ) = withContext(Dispatchers.IO) {
        try {
            val dataDir = File(applicationContext.filesDir, DATA_DIR)
            if (!dataDir.exists()) {
                dataDir.mkdirs()
            }
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd-HH", Locale.getDefault())
            val filename = "app_usage_${dateFormat.format(Date(archivalTime))}.json"
            val file = File(dataDir, filename)
            
            val jsonArray = JSONArray()
            appData.forEach { data ->
                val jsonObj = JSONObject()
                data.forEach { (key, value) ->
                    jsonObj.put(key, value)
                }
                jsonArray.put(jsonObj)
            }
            
            FileWriter(file).use { writer ->
                writer.write(jsonArray.toString(2))
            }
            
            Log.i(TAG, "Stored ${appData.size} app usage records to ${file.name}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error storing app data", e)
            throw e
        }
    }
    
    /**
     * Process and store network data
     */
    private suspend fun processAndStoreNetworkData(
        networkData: List<Map<String, Any>>,
        archivalTime: Long
    ) = withContext(Dispatchers.IO) {
        try {
            val dataDir = File(applicationContext.filesDir, DATA_DIR)
            if (!dataDir.exists()) {
                dataDir.mkdirs()
            }
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd-HH", Locale.getDefault())
            val filename = "network_usage_${dateFormat.format(Date(archivalTime))}.json"
            val file = File(dataDir, filename)
            
            val jsonArray = JSONArray()
            networkData.forEach { data ->
                val jsonObj = JSONObject()
                data.forEach { (key, value) ->
                    jsonObj.put(key, value)
                }
                jsonArray.put(jsonObj)
            }
            
            FileWriter(file).use { writer ->
                writer.write(jsonArray.toString(2))
            }
            
            Log.i(TAG, "Stored ${networkData.size} network usage records to ${file.name}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error storing network data", e)
            throw e
        }
    }
    
    /**
     * Process and store system metrics data
     */
    private suspend fun processAndStoreMetricsData(
        metricsData: Map<String, Map<String, Double>>,
        archivalTime: Long
    ) = withContext(Dispatchers.IO) {
        try {
            val dataDir = File(applicationContext.filesDir, DATA_DIR)
            if (!dataDir.exists()) {
                dataDir.mkdirs()
            }
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd-HH", Locale.getDefault())
            val filename = "system_metrics_${dateFormat.format(Date(archivalTime))}.json"
            val file = File(dataDir, filename)
            
            val jsonObj = JSONObject()
            metricsData.forEach { (packageName, metrics) ->
                val metricsObj = JSONObject()
                metrics.forEach { (metricName, value) ->
                    metricsObj.put(metricName, value)
                }
                jsonObj.put(packageName, metricsObj)
            }
            
            FileWriter(file).use { writer ->
                writer.write(jsonObj.toString(2))
            }
            
            Log.i(TAG, "Stored system metrics for ${metricsData.size} apps to ${file.name}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error storing metrics data", e)
            throw e
        }
    }
    
    /**
     * Generate hourly summary from collected data
     */
    private suspend fun generateHourlySummary(archivalTime: Long) = withContext(Dispatchers.Default) {
        try {
            // Aggregate data from the hour
            val summary = mutableMapOf<String, Any>()
            
            summary["timestamp"] = archivalTime
            summary["totalApps"] = dataCache.size
            summary["archivalPeriod"] = ARCHIVAL_PERIOD_HOURS
            summary["generatedAt"] = System.currentTimeMillis()
            
            // Store summary
            val dataDir = File(applicationContext.filesDir, DATA_DIR)
            val summaryFile = File(dataDir, "hourly_summaries.json")
            
            val summaryArray = if (summaryFile.exists()) {
                try {
                    JSONArray(summaryFile.readText())
                } catch (e: Exception) {
                    JSONArray()
                }
            } else {
                JSONArray()
            }
            
            val summaryJson = JSONObject()
            summary.forEach { (key, value) ->
                summaryJson.put(key, value)
            }
            summaryArray.put(summaryJson)
            
            FileWriter(summaryFile).use { writer ->
                writer.write(summaryArray.toString(2))
            }
            
            Log.i(TAG, "Generated hourly summary for ${Date(archivalTime)}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error generating hourly summary", e)
        }
    }
    
    /**
     * Perform data cleanup based on retention settings
     */
    private suspend fun performDataCleanup() = withContext(Dispatchers.IO) {
        try {
            val dataDir = File(applicationContext.filesDir, DATA_DIR)
            if (!dataDir.exists()) return@withContext
            
            val cutoffTime = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(DATA_RETENTION_DAYS.toLong())
            val cutoffDate = Date(cutoffTime)
            
            val filesToDelete = dataDir.listFiles()?.filter { file ->
                file.lastModified() < cutoffTime
            } ?: emptyList()
            
            var deletedFiles = 0
            var totalSizeFreed = 0L
            
            filesToDelete.forEach { file ->
                try {
                    totalSizeFreed += file.length()
                    if (file.delete()) {
                        deletedFiles++
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to delete file ${file.name}: ${e.message}")
                }
            }
            
            Log.i(TAG, "Data cleanup completed: deleted $deletedFiles files, freed ${totalSizeFreed / 1024}KB")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error during data cleanup", e)
        }
    }
    
    override suspend fun getForegroundInfo(): androidx.work.ForegroundInfo {
        return androidx.work.ForegroundInfo(
            1001,
            android.app.Notification.Builder(applicationContext, "data_archival")
                .setContentTitle("NetVigilant Data Archival")
                .setContentText("Processing usage data...")
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .build()
        )
    }
}
