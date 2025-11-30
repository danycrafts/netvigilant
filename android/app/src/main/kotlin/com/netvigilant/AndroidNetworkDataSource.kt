package com.netvigilant

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.TrafficStats
import android.os.Build
import android.os.RemoteException
import android.util.Log
import androidx.annotation.RequiresApi
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.concurrent.ConcurrentHashMap

class NetworkDataException(message: String, cause: Throwable? = null) : Exception(message, cause)

@RequiresApi(Build.VERSION_CODES.M)
class AndroidNetworkDataSource(private val context: Context) {

    private val networkStatsManager =
        context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val usageStatsManager =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    private val packageManager: PackageManager = context.packageManager

    private val _realTimeTrafficFlow = MutableSharedFlow<Map<String, Double>>(
        replay = 0,
        extraBufferCapacity = 1,
        onBufferOverflow =  kotlinx.coroutines.channels.BufferOverflow.DROP_OLDEST
    )
    val realTimeTrafficFlow: SharedFlow<Map<String, Double>> = _realTimeTrafficFlow

    private var monitoringJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO)

    // App discovery integration
    private var appDiscoveryManager: AppDiscoveryManager? = null
    private val packageNameCache = ConcurrentHashMap<Int, String>()
    private val appNameCache = ConcurrentHashMap<String, String>()

    companion object {
        private const val STREAM_INTERVAL_MS = 200L // 5 updates per second
    }

    /**
     * Set the app discovery manager for enhanced app information
     */
    fun setAppDiscoveryManager(manager: AppDiscoveryManager) {
        appDiscoveryManager = manager
    }

    fun getHistoricalNetworkUsage(start: Long, end: Long): List<Map<String, Any>> {
        val networkTrafficList = mutableListOf<Map<String, Any>>()
        try {
            // Query for Wi-Fi usage
            val wifiBuckets = networkStatsManager.queryDetails(
                ConnectivityManager.TYPE_WIFI,
                null,
                start,
                end
            )
            processNetworkStatsBuckets(wifiBuckets, ConnectivityManager.TYPE_WIFI, networkTrafficList)

            // Query for Mobile usage
            // Requires active mobile connection or else it might throw an exception on some devices
            // Or only query if device has mobile capability
            if (connectivityManager.activeNetworkInfo?.type == ConnectivityManager.TYPE_MOBILE ||
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { // More robust check for mobile presence
                val mobileBuckets = networkStatsManager.queryDetails(
                    ConnectivityManager.TYPE_MOBILE,
                    null,
                    start,
                    end
                )
                processNetworkStatsBuckets(mobileBuckets, ConnectivityManager.TYPE_MOBILE, networkTrafficList)
            }


        } catch (e: RemoteException) {
            e.printStackTrace()
            throw NetworkDataException("Failed to query network stats: ${e.message}", e)
        } catch (e: Exception) {
            e.printStackTrace()
            // Catch other potential exceptions like IllegalArgumentException if mobile type is not present
        }
        return networkTrafficList
    }

    private fun processNetworkStatsBuckets(
        buckets: NetworkStats,
        networkType: Int,
        networkTrafficList: MutableList<Map<String, Any>>
    ) {
        val networkTypeName = when (networkType) {
            ConnectivityManager.TYPE_WIFI -> "wifi"
            ConnectivityManager.TYPE_MOBILE -> "mobile"
            else -> "unknown"
        }
        while (buckets.hasNextBucket()) {
            val b = NetworkStats.Bucket()
            buckets.getNextBucket(b)

            val packageName = getPackageNameForUid(b.uid)
            val appName = getAppNameForPackage(packageName)

            networkTrafficList.add(
                mapOf(
                    "uid" to b.uid,
                    "packageName" to packageName,
                    "appName" to appName,
                    "rxBytes" to b.rxBytes,
                    "txBytes" to b.txBytes,
                    "timestamp" to b.startTimeStamp,
                    "networkType" to networkTypeName, // Send string name to Dart
                    "isBackgroundTraffic" to determineBackgroundTraffic(b.uid, b.startTimeStamp, b.endTimeStamp)
                )
            )
        }
        buckets.close()
    }


    fun startRealTimeMonitoring() {
        if (monitoringJob?.isActive == true) return // Already monitoring

        monitoringJob = scope.launch {
            var lastTotalRxBytes = TrafficStats.getTotalRxBytes()
            var lastTotalTxBytes = TrafficStats.getTotalTxBytes()
            var lastTimestamp = System.currentTimeMillis()

            while (isActive) {
                delay(STREAM_INTERVAL_MS)

                val currentTotalRxBytes = TrafficStats.getTotalRxBytes()
                val currentTotalTxBytes = TrafficStats.getTotalTxBytes()
                val currentTimestamp = System.currentTimeMillis()

                val rxBytesDelta = currentTotalRxBytes - lastTotalRxBytes
                val txBytesDelta = currentTotalTxBytes - lastTotalTxBytes
                val timeDeltaSeconds = (currentTimestamp - lastTimestamp) / 1000.0

                val downloadSpeed = if (timeDeltaSeconds > 0) (rxBytesDelta / timeDeltaSeconds) else 0.0
                val uploadSpeed = if (timeDeltaSeconds > 0) (txBytesDelta / timeDeltaSeconds) else 0.0

                val metrics = mapOf(
                    "uplinkSpeed" to uploadSpeed,
                    "downlinkSpeed" to downloadSpeed
                )
                _realTimeTrafficFlow.emit(metrics)

                lastTotalRxBytes = currentTotalRxBytes
                lastTotalTxBytes = currentTotalTxBytes
                lastTimestamp = currentTimestamp
            }
        }
    }

    fun stopRealTimeMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = null
    }

    private fun determineBackgroundTraffic(uid: Int, startTime: Long, endTime: Long): Boolean {
        try {
            val packageNames = packageManager.getPackagesForUid(uid)
            if (packageNames.isNullOrEmpty()) return true

            val packageName = packageNames.first()
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                startTime,
                endTime
            )

            val appUsageStats = usageStats.firstOrNull { it.packageName == packageName }
            return if (appUsageStats != null) {
                val foregroundTime = appUsageStats.totalTimeInForeground
                val totalTime = endTime - startTime
                foregroundTime < (totalTime * 0.1)
            } else {
                true
            }
        } catch (e: Exception) {
            return true
        }
    }

    fun getAggregatedNetworkUsageByUid(start: Long, end: Long): Map<String, Map<String, Any>> {
        val aggregatedUsage = mutableMapOf<String, MutableMap<String, Any>>()

        try {
            val wifiBuckets = networkStatsManager.queryDetails(
                ConnectivityManager.TYPE_WIFI,
                null,
                start,
                end
            )
            aggregateNetworkStatsByUid(wifiBuckets, aggregatedUsage, "wifi")

            if (connectivityManager.activeNetworkInfo?.type == ConnectivityManager.TYPE_MOBILE ||
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val mobileBuckets = networkStatsManager.queryDetails(
                    ConnectivityManager.TYPE_MOBILE,
                    null,
                    start,
                    end
                )
                aggregateNetworkStatsByUid(mobileBuckets, aggregatedUsage, "mobile")
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }

        return aggregatedUsage
    }

    private fun aggregateNetworkStatsByUid(
        buckets: NetworkStats,
        aggregatedUsage: MutableMap<String, MutableMap<String, Any>>,
        networkType: String
    ) {
        while (buckets.hasNextBucket()) {
            val bucket = NetworkStats.Bucket()
            buckets.getNextBucket(bucket)

            val uid = bucket.uid.toString()
            val packageName = packageManager.getPackagesForUid(bucket.uid)?.firstOrNull() ?: "unknown"

            val existing = aggregatedUsage.getOrPut(uid) {
                mutableMapOf(
                    "packageName" to packageName,
                    "totalRxBytes" to 0L,
                    "totalTxBytes" to 0L,
                    "networkTypes" to mutableSetOf<String>()
                )
            }

            existing["totalRxBytes"] = (existing["totalRxBytes"] as Long) + bucket.rxBytes
            existing["totalTxBytes"] = (existing["totalTxBytes"] as Long) + bucket.txBytes
            (existing["networkTypes"] as MutableSet<String>).add(networkType)
        }
        buckets.close()
    }

    /**
     * Get package name for UID with caching
     */
    private fun getPackageNameForUid(uid: Int): String {
        return packageNameCache.getOrPut(uid) {
            packageManager.getPackagesForUid(uid)?.firstOrNull() ?: "unknown"
        }
    }

    /**
     * Get app name for package with enhanced discovery integration
     */
    private fun getAppNameForPackage(packageName: String): String {
        if (packageName == "unknown") return packageName
        
        return appNameCache.getOrPut(packageName) {
            try {
                // Try to get from app discovery manager first (has better caching)
                appDiscoveryManager?.let { manager ->
                    try {
                        runBlocking {
                            val apps = manager.searchApps(packageName, includeSystemApps = true)
                            apps.firstOrNull { it.packageName == packageName }?.appName
                        }
                    } catch (e: Exception) {
                        null
                    }
                } ?: run {
                    // Fallback to package manager
                    packageManager.getApplicationLabel(
                        packageManager.getApplicationInfo(
                            packageName,
                            PackageManager.GET_META_DATA
                        )
                    ).toString()
                }
            } catch (e: PackageManager.NameNotFoundException) {
                packageName // Fallback to package name if app name not found
            } catch (e: Exception) {
                packageName
            }
        }
    }

    /**
     * Clear all caches
     */
    fun clearCaches() {
        packageNameCache.clear()
        appNameCache.clear()
    }

    /**
     * Get enhanced network usage with app details
     */
    suspend fun getEnhancedNetworkUsage(
        start: Long, 
        end: Long,
        appDiscoveryManager: AppDiscoveryManager
    ): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        setAppDiscoveryManager(appDiscoveryManager)
        
        try {
            val networkData = getHistoricalNetworkUsage(start, end)
            val packageNames = networkData.mapNotNull { it["packageName"] as? String }.distinct()
            
            // Get app metadata for all packages
            val appMetadataMap = try {
                val allApps = appDiscoveryManager.discoverAllApps(includeSystemApps = true, includeIcons = false)
                allApps.associateBy { it.packageName }
            } catch (e: Exception) {
                Log.w("NetworkDataSource", "Failed to get app metadata: ${e.message}")
                emptyMap()
            }
            
            // Enhance network data with app metadata
            networkData.map { networkItem ->
                val packageName = networkItem["packageName"] as? String ?: "unknown"
                val appMetadata = appMetadataMap[packageName]
                
                networkItem.toMutableMap().apply {
                    appMetadata?.let { metadata ->
                        put("category", metadata.category)
                        put("isSystemApp", metadata.isSystemApp)
                        put("appSize", metadata.appSize)
                        put("versionName", metadata.versionName)
                        put("isEnabled", metadata.isEnabled)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("NetworkDataSource", "Error getting enhanced network usage", e)
            emptyList()
        }
    }

    fun dispose() {
        clearCaches()
        scope.cancel()
    }
}
