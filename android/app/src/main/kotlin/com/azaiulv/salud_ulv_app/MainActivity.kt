package com.azaiulv.salud_ulv_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.azaiulv.salud_ulv_app/steps",
        ).setStreamHandler(StepCounterStreamHandler(this))
    }
}

private class StepCounterStreamHandler(context: Context) :
    EventChannel.StreamHandler,
    SensorEventListener {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    private val stepDetector = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
    private var events: EventChannel.EventSink? = null
    private var counterBaseline: Long? = null
    private var confirmedSteps = 0L
    private var detectorSteps = 0L

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        events = eventSink
        counterBaseline = null
        confirmedSteps = 0
        detectorSteps = 0
        sensorManager.unregisterListener(this)

        if (stepCounter == null && stepDetector == null) {
            eventSink.error("STEP_SENSOR_UNAVAILABLE", "This device has no native step counter", null)
            return
        }

        try {
            stepCounter?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL, 0)
            }
            stepDetector?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL, 0)
            }
            emitReading()
        } catch (error: SecurityException) {
            eventSink.error("ACTIVITY_PERMISSION_DENIED", error.message, null)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        events = null
        counterBaseline = null
        confirmedSteps = 0
        detectorSteps = 0
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_STEP_DETECTOR -> {
                detectorSteps += event.values.firstOrNull()?.toLong()?.coerceAtLeast(1) ?: 1
            }
            Sensor.TYPE_STEP_COUNTER -> {
                val total = event.values.firstOrNull()?.toLong() ?: return
                val baseline = counterBaseline ?: (total - detectorSteps).coerceAtLeast(0).also {
                    counterBaseline = it
                }
                confirmedSteps = maxOf(confirmedSteps, (total - baseline).coerceAtLeast(0))
            }
            else -> return
        }
        emitReading()
    }

    private fun emitReading() {
        events?.success(
            mapOf(
                "counterAvailable" to (stepCounter != null),
                "detectorAvailable" to (stepDetector != null),
                "confirmedSteps" to confirmedSteps,
                "liveSteps" to maxOf(confirmedSteps, detectorSteps),
            ),
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
