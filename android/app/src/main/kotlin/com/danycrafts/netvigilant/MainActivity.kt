package com.danycrafts.netvigilant

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_usage_channel"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    try {
                        val usageStats = getUsageStats()
                        result.success(usageStats)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get usage stats: ${e.message}", null)
                    }
                }
                "getAppUsageInfo" -> {
                    try {
                        val packageName = call.arguments as? String
                        if (packageName != null) {
                            val usageInfo = getAppUsageInfo(packageName)
                            result.success(usageInfo)
                        } else {
                            result.error("INVALID_ARGUMENT", "Package name is required", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get app usage info: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = packageManager
        
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -30) // Last 30 days
        val startTime = cal.timeInMillis
        val endTime = System.currentTimeMillis()

        val usageStats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val result = mutableListOf<Map<String, Any>>()

        for (usageStat in usageStats) {
            if (usageStat.totalTimeInForeground > 0) {
                try {
                    val appInfo = packageManager.getApplicationInfo(usageStat.packageName, 0)
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    
                    result.add(mapOf(
                        "packageName" to usageStat.packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to usageStat.totalTimeInForeground,
                        "lastTimeUsed" to usageStat.lastTimeUsed,
                        "launchCount" to 1 // UsageStats doesn't provide launch count directly
                    ))
                } catch (e: PackageManager.NameNotFoundException) {
                    // App might be uninstalled
                }
            }
        }

        return result.sortedByDescending { (it["totalTimeInForeground"] as Long) }
    }

    private fun getAppUsageInfo(packageName: String): Map<String, Any>? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = packageManager
        
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -30)
        val startTime = cal.timeInMillis
        val endTime = System.currentTimeMillis()

        val usageStats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        
        for (usageStat in usageStats) {
            if (usageStat.packageName == packageName && usageStat.totalTimeInForeground > 0) {
                try {
                    val appInfo = packageManager.getApplicationInfo(packageName, 0)
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    
                    return mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to usageStat.totalTimeInForeground,
                        "lastTimeUsed" to usageStat.lastTimeUsed,
                        "launchCount" to 1
                    )
                } catch (e: PackageManager.NameNotFoundException) {
                    // App might be uninstalled
                }
            }
        }
        
        return null
    }
}
