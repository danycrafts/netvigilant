package com.example.netvigilant

import android.content.Context
import io.flutter.plugin.common.EventChannel
import com.netvigilant.NetworkMonitorForegroundService
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.catch

class TrafficStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null
    private var job: Job? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        try {
            NetworkMonitorForegroundService.getRealTimeTrafficFlow()?.let { trafficFlow ->
                job = scope.launch {
                    trafficFlow
                        .catch { e ->
                            eventSink?.error("STREAM_ERROR", "Real-time monitoring error: ${e.message}", null)
                        }
                        .collect { metrics ->
                            eventSink?.success(metrics)
                        }
                }
            } ?: run {
                startMonitoringServiceAndRetry()
            }
        } catch (e: Exception) {
            eventSink?.error("INITIALIZATION_ERROR", "Failed to initialize monitoring: ${e.message}", null)
        }
    }

    private fun startMonitoringServiceAndRetry() {
        try {
            val serviceIntent = android.content.Intent(context, com.netvigilant.NetworkMonitorForegroundService::class.java)
            serviceIntent.action = com.netvigilant.NetworkMonitorForegroundService.ACTION_START_MONITORING
            context.startForegroundService(serviceIntent)
            
            scope.launch {
                kotlinx.coroutines.delay(1000)
                
                NetworkMonitorForegroundService.getRealTimeTrafficFlow()?.let { trafficFlow ->
                    job = launch {
                        trafficFlow
                            .catch { e ->
                                eventSink?.error("STREAM_ERROR", "Real-time monitoring error: ${e.message}", null)
                            }
                            .collect { metrics ->
                                eventSink?.success(metrics)
                            }
                    }
                } ?: run {
                    eventSink?.error("SERVICE_UNAVAILABLE", "Monitoring service could not be started", null)
                }
            }
        } catch (e: Exception) {
            eventSink?.error("SERVICE_START_ERROR", "Failed to start monitoring service: ${e.message}", null)
        }
    }

    override fun onCancel(arguments: Any?) {
        job?.cancel()
        eventSink = null
    }
}
