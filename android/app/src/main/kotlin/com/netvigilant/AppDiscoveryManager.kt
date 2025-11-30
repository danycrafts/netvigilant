package com.netvigilant

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Log
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.util.concurrent.ConcurrentHashMap
import android.util.Base64
import java.util.concurrent.Executors

/**
 * Comprehensive app discovery and metadata manager
 * Dynamically discovers all installed apps with full metadata
 */
class AppDiscoveryManager(private val context: Context) {
    
    companion object {
        private const val TAG = "AppDiscoveryManager"
        private const val ICON_SIZE = 64 // Icon size in dp
        private const val CACHE_EXPIRY_MS = 300_000L // 5 minutes
    }
    
    private val packageManager = context.packageManager
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val diskIODispatcher = Dispatchers.IO.limitedParallelism(2)
    private val computationDispatcher = Dispatchers.Default.limitedParallelism(4)
    private val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())
    
    // Thread-safe caches for app data
    private val appMetadataCache = ConcurrentHashMap<String, AppMetadata>()
    private val appIconCache = ConcurrentHashMap<String, String>() // Base64 encoded icons
    private val lastCacheUpdate = ConcurrentHashMap<String, Long>()
    
    data class AppMetadata(
        val packageName: String,
        val appName: String,
        val versionName: String,
        val versionCode: Long,
        val isSystemApp: Boolean,
        val isEnabled: Boolean,
        val installTime: Long,
        val lastUpdateTime: Long,
        val targetSdkVersion: Int,
        val minSdkVersion: Int,
        val permissions: List<String>,
        val category: String,
        val appSize: Long,
        val iconBase64: String? = null
    )
    
    data class AppUsageInfo(
        val metadata: AppMetadata,
        val isRunning: Boolean,
        val cpuUsage: Double,
        val memoryUsage: Double,
        val batteryUsage: Double,
        val networkUsage: Long,
        val lastUsedTime: Long,
        val totalTimeInForeground: Long
    )
    
    /**
     * Discover all installed apps with comprehensive metadata
     */
    suspend fun discoverAllApps(
        includeSystemApps: Boolean = false,
        includeIcons: Boolean = true
    ): List<AppMetadata> = withContext(computationDispatcher) {
        
        Log.i(TAG, "Starting comprehensive app discovery...")
        val startTime = System.currentTimeMillis()
        
        try {
            // Get all installed packages using disk I/O dispatcher
            val installedPackages = withContext(diskIODispatcher) {
                packageManager.getInstalledPackages(
                    PackageManager.GET_PERMISSIONS or 
                    PackageManager.GET_META_DATA or
                    PackageManager.GET_CONFIGURATIONS
                )
            }
            
            Log.i(TAG, "Found ${installedPackages.size} total packages")
            
            // Filter packages based on criteria
            val filteredPackages = installedPackages.filter { packageInfo ->
                val appInfo = packageInfo.applicationInfo ?: return@filter false
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                
                // Include based on system app preference
                if (!includeSystemApps && isSystemApp) {
                    false
                } else {
                    // Only include apps that can be launched (have a main activity)
                    packageManager.getLaunchIntentForPackage(packageInfo.packageName) != null ||
                    isSystemApp // Include system apps even without launch intent
                }
            }
            
            Log.i(TAG, "Processing ${filteredPackages.size} filtered packages")
            
            // Process apps concurrently in optimized batches based on CPU cores
            val optimalBatchSize = (filteredPackages.size / Runtime.getRuntime().availableProcessors()).coerceAtLeast(5).coerceAtMost(20)
            val allApps = mutableListOf<AppMetadata>()
            
            filteredPackages.chunked(optimalBatchSize).map { batch ->
                async(computationDispatcher) {
                    batch.mapNotNull { packageInfo ->
                        try {
                            processAppPackage(packageInfo.packageName, includeIcons)
                        } catch (e: Exception) {
                            Log.w(TAG, "Error processing app ${packageInfo.packageName}: ${e.message}")
                            null
                        }
                    }
                }
            }.awaitAll().forEach { batchResults ->
                allApps.addAll(batchResults)
            }
            
            // Sort apps by name for better UX
            val sortedApps = allApps.sortedBy { it.appName.lowercase() }
            
            Log.i(TAG, "App discovery completed in ${System.currentTimeMillis() - startTime}ms, found ${sortedApps.size} apps")
            sortedApps
            
        } catch (e: Exception) {
            Log.e(TAG, "Error during app discovery", e)
            emptyList()
        }
    }
    
    /**
     * Get real-time app usage information for all apps
     */
    suspend fun getAllAppsWithUsageInfo(
        systemMetricsManager: SystemMetricsManager
    ): List<AppUsageInfo> = withContext(Dispatchers.IO) {
        
        try {
            val allApps = discoverAllApps(includeSystemApps = false, includeIcons = false)
            Log.i(TAG, "Getting usage info for ${allApps.size} apps")
            
            // Get usage metrics for all apps concurrently
            val packageNames = allApps.map { it.packageName }
            val metricsData = systemMetricsManager.getAppUsageWithMetrics(packageNames)
            
            // Combine metadata with usage info
            allApps.map { metadata ->
                val metrics = metricsData[metadata.packageName]
                
                AppUsageInfo(
                    metadata = metadata,
                    isRunning = isAppRunning(metadata.packageName),
                    cpuUsage = (metrics?.get("cpuUsage") as? Double) ?: 0.0,
                    memoryUsage = (metrics?.get("memoryUsage") as? Double) ?: 0.0,
                    batteryUsage = (metrics?.get("batteryUsage") as? Double) ?: 0.0,
                    networkUsage = (metrics?.get("networkUsage") as? Number)?.toLong() ?: 0L,
                    lastUsedTime = getLastUsedTime(metadata.packageName),
                    totalTimeInForeground = getTotalTimeInForeground(metadata.packageName)
                )
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting apps with usage info", e)
            emptyList()
        }
    }
    
    /**
     * Process individual app package to extract comprehensive metadata
     */
    private suspend fun processAppPackage(
        packageName: String, 
        includeIcon: Boolean
    ): AppMetadata? = withContext(Dispatchers.Default) {
        
        try {
            // Check cache first
            val cached = appMetadataCache[packageName]
            val lastUpdate = lastCacheUpdate[packageName] ?: 0
            
            if (cached != null && (System.currentTimeMillis() - lastUpdate) < CACHE_EXPIRY_MS) {
                return@withContext cached
            }
            
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            val applicationInfo = packageInfo.applicationInfo ?: return@withContext null
            
            // Extract app metadata
            val appName = packageManager.getApplicationLabel(applicationInfo).toString()
            val versionName = packageInfo.versionName ?: "Unknown"
            val versionCode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageInfo.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                packageInfo.versionCode.toLong()
            }
            
            // System app detection
            val isSystemApp = (applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val isEnabled = applicationInfo.enabled
            
            // Installation and update times
            val installTime = packageInfo.firstInstallTime
            val lastUpdateTime = packageInfo.lastUpdateTime
            
            // SDK versions
            val targetSdkVersion = applicationInfo.targetSdkVersion
            val minSdkVersion = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                applicationInfo.minSdkVersion
            } else {
                1 // Default for older Android versions
            }
            
            // Permissions
            val permissions = packageInfo.requestedPermissions?.toList() ?: emptyList()
            
            // App category
            val category = getAppCategory(applicationInfo)
            
            // App size (approximate)
            val appSize = getAppSize(applicationInfo)
            
            // App icon (if requested)
            val iconBase64 = if (includeIcon) {
                getAppIconBase64(applicationInfo)
            } else null
            
            val metadata = AppMetadata(
                packageName = packageName,
                appName = appName,
                versionName = versionName,
                versionCode = versionCode,
                isSystemApp = isSystemApp,
                isEnabled = isEnabled,
                installTime = installTime,
                lastUpdateTime = lastUpdateTime,
                targetSdkVersion = targetSdkVersion,
                minSdkVersion = minSdkVersion,
                permissions = permissions,
                category = category,
                appSize = appSize,
                iconBase64 = iconBase64
            )
            
            // Cache the result
            appMetadataCache[packageName] = metadata
            lastCacheUpdate[packageName] = System.currentTimeMillis()
            
            metadata
            
        } catch (e: Exception) {
            Log.w(TAG, "Error processing package $packageName: ${e.message}")
            null
        }
    }
    
    /**
     * Get app category based on ApplicationInfo
     */
    private fun getAppCategory(applicationInfo: ApplicationInfo): String {
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                when (applicationInfo.category) {
                    ApplicationInfo.CATEGORY_GAME -> "Game"
                    ApplicationInfo.CATEGORY_AUDIO -> "Audio"
                    ApplicationInfo.CATEGORY_VIDEO -> "Video"
                    ApplicationInfo.CATEGORY_IMAGE -> "Image"
                    ApplicationInfo.CATEGORY_SOCIAL -> "Social"
                    ApplicationInfo.CATEGORY_NEWS -> "News"
                    ApplicationInfo.CATEGORY_MAPS -> "Maps"
                    ApplicationInfo.CATEGORY_PRODUCTIVITY -> "Productivity"
                    ApplicationInfo.CATEGORY_ACCESSIBILITY -> "Accessibility"
                    else -> "Other"
                }
            } else {
                // For older Android versions, categorize based on package name patterns
                when {
                    applicationInfo.packageName.contains("game", ignoreCase = true) -> "Game"
                    applicationInfo.packageName.contains("music", ignoreCase = true) -> "Audio"
                    applicationInfo.packageName.contains("video", ignoreCase = true) -> "Video"
                    applicationInfo.packageName.contains("photo", ignoreCase = true) -> "Image"
                    applicationInfo.packageName.contains("social", ignoreCase = true) -> "Social"
                    applicationInfo.packageName.contains("news", ignoreCase = true) -> "News"
                    applicationInfo.packageName.contains("map", ignoreCase = true) -> "Maps"
                    (applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 -> "System"
                    else -> "Other"
                }
            }
        } catch (e: Exception) {
            "Unknown"
        }
    }
    
    /**
     * Get approximate app size
     */
    private fun getAppSize(applicationInfo: ApplicationInfo): Long {
        return try {
            val sourceDir = applicationInfo.sourceDir
            val file = java.io.File(sourceDir)
            file.length()
        } catch (e: Exception) {
            0L
        }
    }
    
    /**
     * Convert app icon to base64 string
     */
    private suspend fun getAppIconBase64(applicationInfo: ApplicationInfo): String? = withContext(Dispatchers.Default) {
        try {
            // Check icon cache first
            val cached = appIconCache[applicationInfo.packageName]
            if (cached != null) {
                return@withContext cached
            }
            
            val drawable = packageManager.getApplicationIcon(applicationInfo)
            val bitmap = drawableToBitmap(drawable)
            val scaledBitmap = Bitmap.createScaledBitmap(bitmap, ICON_SIZE, ICON_SIZE, true)
            
            val outputStream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 90, outputStream)
            val byteArray = outputStream.toByteArray()
            val base64 = Base64.encodeToString(byteArray, Base64.DEFAULT)
            
            // Cache the result
            appIconCache[applicationInfo.packageName] = base64
            
            base64
        } catch (e: Exception) {
            Log.w(TAG, "Error converting icon to base64 for ${applicationInfo.packageName}: ${e.message}")
            null
        }
    }
    
    /**
     * Convert drawable to bitmap
     */
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1),
            drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888
        )
        
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        
        return bitmap
    }
    
    /**
     * Check if app is currently running
     */
    private fun isAppRunning(packageName: String): Boolean {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val runningProcesses = activityManager.runningAppProcesses
            runningProcesses?.any { it.processName == packageName } == true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Get last used time for app (placeholder - would need UsageStatsManager)
     */
    private fun getLastUsedTime(packageName: String): Long {
        // This would typically use UsageStatsManager
        // For now, return current time as placeholder
        return System.currentTimeMillis()
    }
    
    /**
     * Get total time in foreground (placeholder - would need UsageStatsManager)
     */
    private fun getTotalTimeInForeground(packageName: String): Long {
        // This would typically use UsageStatsManager
        // For now, return 0 as placeholder
        return 0L
    }
    
    /**
     * Search apps by name or package name
     */
    suspend fun searchApps(
        query: String,
        includeSystemApps: Boolean = false
    ): List<AppMetadata> = withContext(Dispatchers.Default) {
        
        val allApps = discoverAllApps(includeSystemApps, includeIcons = false)
        
        allApps.filter { app ->
            app.appName.contains(query, ignoreCase = true) ||
            app.packageName.contains(query, ignoreCase = true)
        }
    }
    
    /**
     * Get apps by category
     */
    suspend fun getAppsByCategory(category: String): List<AppMetadata> = withContext(Dispatchers.Default) {
        val allApps = discoverAllApps(includeSystemApps = false, includeIcons = false)
        allApps.filter { it.category.equals(category, ignoreCase = true) }
    }
    
    /**
     * Get recently updated apps
     */
    suspend fun getRecentlyUpdatedApps(daysBack: Int = 7): List<AppMetadata> = withContext(Dispatchers.Default) {
        val cutoffTime = System.currentTimeMillis() - (daysBack * 24 * 60 * 60 * 1000L)
        val allApps = discoverAllApps(includeSystemApps = false, includeIcons = false)
        
        allApps.filter { it.lastUpdateTime > cutoffTime }
            .sortedByDescending { it.lastUpdateTime }
    }
    
    /**
     * Clear all caches
     */
    fun clearCache() {
        appMetadataCache.clear()
        appIconCache.clear()
        lastCacheUpdate.clear()
        Log.i(TAG, "App discovery cache cleared")
    }
    
    /**
     * Get cache statistics
     */
    fun getCacheStats(): Map<String, Any> {
        return mapOf(
            "metadataCacheSize" to appMetadataCache.size,
            "iconCacheSize" to appIconCache.size,
            "cacheUpdates" to lastCacheUpdate.size
        )
    }
    
    /**
     * Cleanup resources
     */
    fun dispose() {
        scope.cancel()
        executor.shutdown()
        clearCache()
    }
}