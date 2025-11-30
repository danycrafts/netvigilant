package com.netvigilant

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.app.usage.NetworkStatsManager
import android.os.Process
import androidx.core.content.ContextCompat
import android.telephony.TelephonyManager
import android.annotation.SuppressLint
import com.netvigilant.AndroidNetworkDataSource
import com.netvigilant.PermissionManager
import com.netvigilant.SystemMetricsManager
import com.netvigilant.AppDiscoveryManager
import kotlinx.coroutines.*

class NetworkStatsHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val androidNetworkDataSource by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            AndroidNetworkDataSource(context)
        } else {
            null
        }
    }
    private val permissionManager by lazy { PermissionManager(context) }
    private val systemMetricsManager by lazy { SystemMetricsManager(context) }
    private val appDiscoveryManager by lazy { AppDiscoveryManager(context) }
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageStatsPermission" -> {
                result.success(permissionManager.hasUsageStatsPermission())
            }
            "getHistoricalNetworkUsage" -> {
                if (!permissionManager.hasUsageStatsPermission()) {
                    result.error("permission_denied", "Usage stats permission is not granted.", null)
                    return
                }

                val startTime = call.argument<Long>("start")!!
                val endTime = call.argument<Long>("end")!!
                val enhanced = call.argument<Boolean>("enhanced") ?: false

                scope.launch {
                    try {
                        val usageList = if (enhanced) {
                            androidNetworkDataSource?.getEnhancedNetworkUsage(startTime, endTime, appDiscoveryManager) ?: emptyList()
                        } else {
                            androidNetworkDataSource?.getHistoricalNetworkUsage(startTime, endTime) ?: emptyList()
                        }
                        result.success(usageList)
                    } catch (e: Exception) {
                        result.error("network_error", "Failed to fetch network usage: ${e.message}", null)
                    }
                }
            }
            "requestUsageStatsPermission" -> {
                permissionManager.requestUsageStatsPermission()
                result.success(null)
            }
            "getAppUsage" -> {
                if (!permissionManager.hasUsageStatsPermission()) {
                    result.error("permission_denied", "Usage stats permission is not granted.", null)
                    return
                }
                
                val startTime = call.argument<Long>("start")!!
                val endTime = call.argument<Long>("end")!!
                
                // Start metrics monitoring if not already running
                systemMetricsManager.startMonitoring()
                
                scope.launch {
                    try {
                        val appUsageList = withContext(Dispatchers.IO) {
                            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                            val packageManager = context.packageManager
                            val usageStats = usageStatsManager.queryUsageStats(
                                UsageStatsManager.INTERVAL_BEST,
                                startTime,
                                endTime
                            )
                            
                            val appUsageList = mutableListOf<Map<String, Any>>()
                            val packageNames = usageStats.map { it.packageName }
                            
                            // Get real metrics for all apps concurrently
                            val metricsData = systemMetricsManager.getAppUsageWithMetrics(packageNames)
                            
                            for (stats in usageStats) {
                                try {
                                    val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                                    val metrics = metricsData[stats.packageName]
                                    
                                    // Get network usage from existing source
                                    val networkUsage = try {
                                        androidNetworkDataSource?.getHistoricalNetworkUsage(startTime, endTime)
                                            ?.filter { it["packageName"] == stats.packageName }
                                            ?.sumOf { ((it["rxBytes"] as? Number)?.toDouble() ?: 0.0) + ((it["txBytes"] as? Number)?.toDouble() ?: 0.0) } ?: 0.0
                                    } catch (e: Exception) { 0.0 }
                                    
                                    val appUsageData = mapOf(
                                        "appName" to appName,
                                        "packageName" to stats.packageName,
                                        "cpuUsage" to (metrics?.get("cpuUsage") ?: 0.0),
                                        "memoryUsage" to (metrics?.get("memoryUsage") ?: 0.0),
                                        "batteryUsage" to (metrics?.get("batteryUsage") ?: 0.0),
                                        "totalTimeInForeground" to stats.totalTimeInForeground,
                                        "launchCount" to stats.firstTimeStamp,
                                        "lastTimeUsed" to stats.lastTimeUsed,
                                        "networkUsage" to networkUsage
                                    )
                                    
                                    appUsageList.add(appUsageData)
                                    
                                } catch (e: Exception) {
                                    // Skip apps that can't be processed
                                }
                            }
                            
                            appUsageList
                        }
                        
                        result.success(appUsageList)
                    } catch (e: Exception) {
                        result.error("usage_error", "Failed to fetch app usage: ${e.message}", null)
                    }
                }
            }
            "startContinuousMonitoring" -> {
                try {
                    val serviceIntent = Intent(context, com.netvigilant.NetworkMonitorForegroundService::class.java)
                    serviceIntent.action = com.netvigilant.NetworkMonitorForegroundService.ACTION_START_MONITORING
                    context.startForegroundService(serviceIntent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("service_error", "Failed to start monitoring service: ${e.message}", null)
                }
            }
            "stopContinuousMonitoring" -> {
                try {
                    val serviceIntent = Intent(context, com.netvigilant.NetworkMonitorForegroundService::class.java)
                    serviceIntent.action = com.netvigilant.NetworkMonitorForegroundService.ACTION_STOP_MONITORING
                    context.startForegroundService(serviceIntent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("service_error", "Failed to stop monitoring service: ${e.message}", null)
                }
            }
            "getHistoricalAppUsage" -> {
                if (!permissionManager.hasUsageStatsPermission()) {
                    result.error("permission_denied", "Usage stats permission is not granted.", null)
                    return
                }
                
                val startTime = call.argument<Long>("start")!!
                val endTime = call.argument<Long>("end")!!
                
                scope.launch {
                    try {
                        val appUsageMap = withContext(Dispatchers.IO) {
                            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                            val packageManager = context.packageManager
                            val usageStats = usageStatsManager.queryUsageStats(
                                UsageStatsManager.INTERVAL_BEST,
                                startTime,
                                endTime
                            ).filter { it.totalTimeInForeground > 0 }
                            
                            val appUsageMap = mutableMapOf<String, Map<String, Any>>()
                            val packageNames = usageStats.map { it.packageName }
                            
                            // Get real metrics concurrently
                            val metricsData = systemMetricsManager.getAppUsageWithMetrics(packageNames)
                            
                            for (stats in usageStats) {
                                try {
                                    val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                                    val metrics = metricsData[stats.packageName]
                                    
                                    // Get network usage
                                    val networkUsage = try {
                                        androidNetworkDataSource?.getAggregatedNetworkUsageByUid(startTime, endTime)
                                            ?.get(stats.packageName) as? Double ?: 0.0
                                    } catch (e: Exception) { 0.0 }
                                    
                                    appUsageMap[stats.packageName] = mapOf(
                                        "appName" to appName,
                                        "packageName" to stats.packageName,
                                        "cpuUsage" to (metrics?.get("cpuUsage") ?: 0.0),
                                        "memoryUsage" to (metrics?.get("memoryUsage") ?: 0.0),
                                        "batteryUsage" to (metrics?.get("batteryUsage") ?: 0.0),
                                        "totalTimeInForeground" to stats.totalTimeInForeground,
                                        "launchCount" to 0,
                                        "lastTimeUsed" to stats.lastTimeUsed,
                                        "networkUsage" to networkUsage
                                    )
                                    
                                } catch (e: Exception) {
                                    // Skip apps that can't be processed
                                }
                            }
                            
                            appUsageMap
                        }
                        
                        result.success(appUsageMap)
                    } catch (e: Exception) {
                        result.error("usage_error", "Failed to fetch historical app usage: ${e.message}", null)
                    }
                }
            }
            "getAggregatedNetworkUsageByUid" -> {
                if (!permissionManager.hasUsageStatsPermission()) {
                    result.error("permission_denied", "Usage stats permission is not granted.", null)
                    return
                }

                val startTime = call.argument<Long>("start")!!
                val endTime = call.argument<Long>("end")!!

                try {
                    val aggregatedUsage = androidNetworkDataSource?.getAggregatedNetworkUsageByUid(startTime, endTime) ?: emptyMap()
                    result.success(aggregatedUsage)
                } catch (e: Exception) {
                    result.error("network_error", "Failed to fetch aggregated network usage: ${e.message}", null)
                }
            }
            "stopSystemMetricsMonitoring" -> {
                try {
                    systemMetricsManager.stopMonitoring()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("metrics_error", "Failed to stop metrics monitoring: ${e.message}", null)
                }
            }
            "getSystemMetrics" -> {
                try {
                    val metrics = systemMetricsManager.getAllCachedMetrics()
                    result.success(metrics)
                } catch (e: Exception) {
                    result.error("metrics_error", "Failed to get system metrics: ${e.message}", null)
                }
            }
            "getAllInstalledApps" -> {
                val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
                val includeIcons = call.argument<Boolean>("includeIcons") ?: false
                
                scope.launch {
                    try {
                        val apps = appDiscoveryManager.discoverAllApps(includeSystemApps, includeIcons)
                        val appsData = apps.map { app ->
                            mapOf(
                                "packageName" to app.packageName,
                                "appName" to app.appName,
                                "versionName" to app.versionName,
                                "versionCode" to app.versionCode,
                                "isSystemApp" to app.isSystemApp,
                                "isEnabled" to app.isEnabled,
                                "installTime" to app.installTime,
                                "lastUpdateTime" to app.lastUpdateTime,
                                "targetSdkVersion" to app.targetSdkVersion,
                                "minSdkVersion" to app.minSdkVersion,
                                "permissions" to app.permissions,
                                "category" to app.category,
                                "appSize" to app.appSize,
                                "iconBase64" to app.iconBase64
                            )
                        }
                        result.success(appsData)
                    } catch (e: Exception) {
                        result.error("discovery_error", "Failed to discover apps: ${e.message}", null)
                    }
                }
            }
            "getAllAppsWithUsage" -> {
                scope.launch {
                    try {
                        val appsWithUsage = appDiscoveryManager.getAllAppsWithUsageInfo(systemMetricsManager)
                        val appsData = appsWithUsage.map { appInfo ->
                            mapOf(
                                "packageName" to appInfo.metadata.packageName,
                                "appName" to appInfo.metadata.appName,
                                "versionName" to appInfo.metadata.versionName,
                                "isSystemApp" to appInfo.metadata.isSystemApp,
                                "category" to appInfo.metadata.category,
                                "isRunning" to appInfo.isRunning,
                                "cpuUsage" to appInfo.cpuUsage,
                                "memoryUsage" to appInfo.memoryUsage,
                                "batteryUsage" to appInfo.batteryUsage,
                                "networkUsage" to appInfo.networkUsage,
                                "lastUsedTime" to appInfo.lastUsedTime,
                                "totalTimeInForeground" to appInfo.totalTimeInForeground,
                                "appSize" to appInfo.metadata.appSize,
                                "installTime" to appInfo.metadata.installTime
                            )
                        }
                        result.success(appsData)
                    } catch (e: Exception) {
                        result.error("usage_discovery_error", "Failed to get apps with usage: ${e.message}", null)
                    }
                }
            }
            "searchApps" -> {
                val query = call.argument<String>("query") ?: ""
                val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
                
                scope.launch {
                    try {
                        val apps = appDiscoveryManager.searchApps(query, includeSystemApps)
                        val appsData = apps.map { app ->
                            mapOf(
                                "packageName" to app.packageName,
                                "appName" to app.appName,
                                "versionName" to app.versionName,
                                "category" to app.category,
                                "isSystemApp" to app.isSystemApp,
                                "appSize" to app.appSize
                            )
                        }
                        result.success(appsData)
                    } catch (e: Exception) {
                        result.error("search_error", "Failed to search apps: ${e.message}", null)
                    }
                }
            }
            "getAppsByCategory" -> {
                val category = call.argument<String>("category") ?: ""
                
                scope.launch {
                    try {
                        val apps = appDiscoveryManager.getAppsByCategory(category)
                        val appsData = apps.map { app ->
                            mapOf(
                                "packageName" to app.packageName,
                                "appName" to app.appName,
                                "versionName" to app.versionName,
                                "category" to app.category,
                                "appSize" to app.appSize
                            )
                        }
                        result.success(appsData)
                    } catch (e: Exception) {
                        result.error("category_error", "Failed to get apps by category: ${e.message}", null)
                    }
                }
            }
            "getRecentlyUpdatedApps" -> {
                val daysBack = call.argument<Int>("daysBack") ?: 7
                
                scope.launch {
                    try {
                        val apps = appDiscoveryManager.getRecentlyUpdatedApps(daysBack)
                        val appsData = apps.map { app ->
                            mapOf(
                                "packageName" to app.packageName,
                                "appName" to app.appName,
                                "versionName" to app.versionName,
                                "lastUpdateTime" to app.lastUpdateTime,
                                "category" to app.category,
                                "appSize" to app.appSize
                            )
                        }
                        result.success(appsData)
                    } catch (e: Exception) {
                        result.error("recent_apps_error", "Failed to get recently updated apps: ${e.message}", null)
                    }
                }
            }
            "clearAppCache" -> {
                try {
                    appDiscoveryManager.clearCache()
                    androidNetworkDataSource?.clearCaches()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("cache_error", "Failed to clear cache: ${e.message}", null)
                }
            }
            "hasIgnoreBatteryOptimizationPermission" -> {
                try {
                    val isIgnoring = permissionManager.hasIgnoreBatteryOptimizationPermission()
                    result.success(isIgnoring)
                } catch (e: Exception) {
                    result.error("permission_error", "Failed to check battery optimization permission: ${e.message}", null)
                }
            }
            "requestIgnoreBatteryOptimizationPermission" -> {
                try {
                    permissionManager.requestIgnoreBatteryOptimizationPermission()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("permission_error", "Failed to request battery optimization exemption: ${e.message}", null)
                }
            }
            "openBatteryOptimizationSettings" -> {
                try {
                    permissionManager.openBatteryOptimizationSettings()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("settings_error", "Failed to open battery optimization settings: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }
    
    /**
     * Cleanup resources when handler is destroyed
     */
    fun dispose() {
        systemMetricsManager.stopMonitoring()
        appDiscoveryManager.dispose()
        androidNetworkDataSource?.dispose()
        scope.cancel()
    }

}