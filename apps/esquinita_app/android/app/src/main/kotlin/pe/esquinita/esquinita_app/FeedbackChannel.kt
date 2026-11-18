package pe.esquinita.esquinita_app

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Scan feedback: a beep (media volume) and a short vibration.
 *
 * Flutter's SystemSound/HapticFeedback follow the system "touch sounds" and
 * "touch vibration" switches, which are often off, so a read could go
 * unnoticed (Spike 1). This uses ToneGenerator and Vibrator directly.
 */
class FeedbackChannel(context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "pe.esquinita/feedback")

    // Can fail on devices without an audio route; then we only vibrate.
    private val tone: ToneGenerator? = try {
        ToneGenerator(AudioManager.STREAM_MUSIC, 100)
    } catch (e: RuntimeException) {
        null
    }

    private val vibrator: Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "success" -> {
                    tone?.startTone(ToneGenerator.TONE_PROP_BEEP, 120)
                    vibrate(longArrayOf(0, 60))
                    result.success(null)
                }
                "error" -> {
                    tone?.startTone(ToneGenerator.TONE_PROP_NACK, 300)
                    vibrate(longArrayOf(0, 90, 80, 90))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun vibrate(pattern: LongArray) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(pattern, -1)
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        tone?.release()
    }
}
