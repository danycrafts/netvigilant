package com.netvigilant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.netvigilant.MainActivity

class NotificationHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val notificationManager: NotificationManager by lazy {
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    companion object {
        const val CHANNEL_ID = "netvigilant_channel"
        const val CHANNEL_NAME = "NetVigilant Notifications"
        const val CHANNEL_DESCRIPTION = "Notifications for network usage and alerts"
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = CHANNEL_DESCRIPTION
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showBasicNotification" -> {
                val id = call.argument<Int>("id") ?: 0
                val title = call.argument<String>("title") ?: "NetVigilant"
                val body = call.argument<String>("body") ?: ""
                val payload = call.argument<String>("payload")
                showBasicNotification(id, title, body, payload)
                result.success(null)
            }
            "showProgressNotification" -> {
                val id = call.argument<Int>("id") ?: 0
                val title = call.argument<String>("title") ?: "NetVigilant"
                val body = call.argument<String>("body") ?: ""
                val progress = call.argument<Int>("progress") ?: 0
                val maxProgress = call.argument<Int>("maxProgress") ?: 100
                val payload = call.argument<String>("payload")
                showProgressNotification(id, title, body, progress, maxProgress, payload)
                result.success(null)
            }
            "updateProgressNotification" -> {
                val id = call.argument<Int>("id") ?: 0
                val title = call.argument<String>("title") ?: "NetVigilant"
                val body = call.argument<String>("body") ?: ""
                val progress = call.argument<Int>("progress") ?: 0
                val maxProgress = call.argument<Int>("maxProgress") ?: 100
                updateProgressNotification(id, title, body, progress, maxProgress)
                result.success(null)
            }
            "cancelNotification" -> {
                val id = call.argument<Int>("id") ?: 0
                cancelNotification(id)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun showBasicNotification(id: Int, title: String, body: String, payload: String?) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("payload", payload)
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // TODO: Use app icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        notificationManager.notify(id, builder.build())
    }

    private fun showProgressNotification(id: Int, title: String, body: String, progress: Int, maxProgress: Int, payload: String?) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("payload", payload)
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // TODO: Use app icon
            .setContentTitle(title)
            .setContentText(body)
            .setProgress(maxProgress, progress, false) // Not indeterminate
            .setPriority(NotificationCompat.PRIORITY_LOW) // Lower priority for ongoing progress
            .setOngoing(true) // User cannot dismiss
            .setContentIntent(pendingIntent)

        notificationManager.notify(id, builder.build())
    }

    private fun updateProgressNotification(id: Int, title: String, body: String, progress: Int, maxProgress: Int) {
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // TODO: Use app icon
            .setContentTitle(title)
            .setContentText(body)
            .setProgress(maxProgress, progress, false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true) // User cannot dismiss
            // No content intent needed for update, but keep it if it was set initially
        
        notificationManager.notify(id, builder.build())
    }

    private fun cancelNotification(id: Int) {
        notificationManager.cancel(id)
    }
}