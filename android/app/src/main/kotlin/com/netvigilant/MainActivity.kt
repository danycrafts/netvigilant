package com.netvigilant

import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.netvigilant.NetworkStatsHandler
import com.netvigilant.TrafficStreamHandler
import com.netvigilant.NotificationHandler
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

@RequiresApi(Build.VERSION_CODES.M)
class MainActivity : FlutterActivity() {
    private val networkStatsChannel = "com.netvigilant/network_stats"
    private val trafficStreamChannel = "com.netvigilant/traffic_stream"
    private val notificationChannel = "com.netvigilant/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val networkStatsHandler = NetworkStatsHandler(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, networkStatsChannel).setMethodCallHandler(networkStatsHandler)

        val trafficStreamHandler = TrafficStreamHandler(context)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, trafficStreamChannel).setStreamHandler(trafficStreamHandler)

        val notificationHandler = NotificationHandler(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannel).setMethodCallHandler(notificationHandler)

        scheduleDataArchivalWorker()
    }

    private fun scheduleDataArchivalWorker() {
        val workRequest = PeriodicWorkRequestBuilder<DataArchivalWorker>(1, TimeUnit.DAYS)
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
            DataArchivalWorker.UNIQUE_WORK_NAME,
            androidx.work.ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }
}