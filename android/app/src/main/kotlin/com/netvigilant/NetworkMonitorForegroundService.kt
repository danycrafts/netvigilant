package com.netvigilant

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class NetworkMonitorForegroundService : Service() {

    private val CHANNEL_ID = "NetworkMonitorServiceChannel"
    private val NOTIFICATION_ID = 1

    companion object {
        const val ACTION_START_MONITORING = "START_MONITORING"
        const val ACTION_STOP_MONITORING = "STOP_MONITORING"
        @SuppressLint("StaticFieldLeak") // Context is application context, safe for static
        private var androidNetworkDataSource: AndroidNetworkDataSource? = null
        
        fun getRealTimeTrafficFlow() = androidNetworkDataSource?.realTimeTrafficFlow
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        if (androidNetworkDataSource == null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            androidNetworkDataSource = AndroidNetworkDataSource(applicationContext)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_MONITORING -> startMonitoring()
            ACTION_STOP_MONITORING -> stopMonitoring()
            else -> startMonitoring()
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NetVigilant Monitoring")
            .setContentText("Monitoring network usage in the background...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    private fun startMonitoring() {
        androidNetworkDataSource?.startRealTimeMonitoring()
    }

    private fun stopMonitoring() {
        androidNetworkDataSource?.stopRealTimeMonitoring()
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        androidNetworkDataSource?.dispose()
        androidNetworkDataSource = null // Clear static instance on destroy
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Network Monitor Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
