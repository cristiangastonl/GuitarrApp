package com.guitarrapp

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.*

class MainActivity: FlutterActivity() {
    private val AUDIO_CHANNEL = "guitarr_app/audio"
    private var audioTrack: AudioTrack? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playClick" -> {
                    val isAccent = call.argument<Boolean>("isAccent") ?: false
                    val frequency = call.argument<Double>("frequency") ?: 800.0
                    val duration = call.argument<Double>("duration") ?: 0.1
                    
                    playClick(frequency, duration)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playClick(frequency: Double, duration: Double) {
        try {
            val sampleRate = 44100
            val samples = (sampleRate * duration).toInt()
            val buffer = ShortArray(samples)

            // Generar onda seno con fade out
            for (i in buffer.indices) {
                val time = i.toDouble() / sampleRate
                val fadeOut = if (time > duration * 0.7) {
                    1.0 - ((time - duration * 0.7) / (duration * 0.3))
                } else 1.0
                
                val sample = (sin(2 * PI * frequency * time) * 32767 * 0.3 * fadeOut).toInt()
                buffer[i] = sample.coerceIn(-32768, 32767).toShort()
            }

            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()

            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(audioAttributes)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(buffer.size * 2)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()

            audioTrack?.let { track ->
                track.write(buffer, 0, buffer.size)
                track.play()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}