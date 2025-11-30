package com.example.netvigilant

import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.netvigilant.NetworkStatsHandler
import com.example.netvigilant.TrafficStreamHandler
import com.netvigilant.NotificationHandler // Import NotificationHandler

@RequiresApi(Build.VERSION_CODES.M)
class MainActivity : FlutterActivity() {
    private val networkStatsChannel = "com.example.netvigilant/network_stats"
    private val trafficStreamChannel = "com.example.netvigilant/traffic_stream"
    private val notificationChannel = "com.netvigilant.app/notifications" // New channel name

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val networkStatsHandler = NetworkStatsHandler(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, networkStatsChannel).setMethodCallHandler(networkStatsHandler)

        val trafficStreamHandler = TrafficStreamHandler(context)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, trafficStreamChannel).setStreamHandler(trafficStreamHandler)

        val notificationHandler = NotificationHandler(context) // Initialize NotificationHandler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannel).setMethodCallHandler(notificationHandler) // Register NotificationHandler
    }
}