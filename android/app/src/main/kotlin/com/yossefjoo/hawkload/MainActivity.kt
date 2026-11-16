package com.yossefjoo.hawkload

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dovid.app/media_trimmer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "trimMedia" -> {
                        val inputPath = call.argument<String>("inputPath") ?: ""
                        val outputPath = call.argument<String>("outputPath") ?: ""
                        val startMs = (call.argument<Number>("startMs") ?: 0).toLong()
                        val endMs = (call.argument<Number>("endMs") ?: 0).toLong()
                        val audioOnly = call.argument<Boolean>("audioOnly") ?: false
                        val rawHeaders = call.argument<Map<String, String>>("headers") ?: emptyMap()

                        thread {
                            try {
                                val ok = trimMediaNative(
                                    inputPath,
                                    outputPath,
                                    startMs,
                                    endMs,
                                    audioOnly,
                                    HashMap(rawHeaders)
                                )
                                if (ok) {
                                    MediaScannerConnection.scanFile(
                                        applicationContext,
                                        arrayOf(outputPath),
                                        null,
                                        null
                                    )
                                }
                                runOnUiThread {
                                    result.success(mapOf("ok" to ok, "outputPath" to outputPath))
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.success(mapOf("ok" to false, "error" to (e.message ?: "trim_error")))
                                }
                            }
                        }
                    }

                    "getMediaInfo" -> {
                        val path = call.argument<String>("path") ?: ""
                        val rawHeaders = call.argument<Map<String, String>>("headers") ?: emptyMap()
                        thread {
                            val info = mutableMapOf<String, Any>()
                            val retriever = MediaMetadataRetriever()
                            try {
                                if (path.startsWith("http://") || path.startsWith("https://")) {
                                    retriever.setDataSource(path, HashMap(rawHeaders))
                                } else {
                                    retriever.setDataSource(path)
                                }
                                val durStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                                val wStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                                val hStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                                val rotStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                                info["ok"] = true
                                info["durationMs"] = durStr?.toLongOrNull() ?: 0L
                                info["width"] = wStr?.toIntOrNull() ?: 0
                                info["height"] = hStr?.toIntOrNull() ?: 0
                                info["rotation"] = rotStr?.toIntOrNull() ?: 0
                            } catch (e: Exception) {
                                info["ok"] = false
                                info["error"] = e.message ?: "meta_error"
                            } finally {
                                try {
                                    retriever.release()
                                } catch (_: Exception) {}
                            }
                            runOnUiThread { result.success(info) }
                        }
                    }

                    "scanFile" -> {
                        val path = call.argument<String>("path") ?: ""
                        if (path.isNotEmpty()) {
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(path),
                                null,
                                null
                            )
                        }
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun trimMediaNative(
        inputPath: String,
        outputPath: String,
        startMs: Long,
        endMs: Long,
        audioOnly: Boolean,
        headers: HashMap<String, String>
    ): Boolean {
        if (inputPath.isEmpty() || outputPath.isEmpty() || endMs <= startMs) return false
        val outFile = File(outputPath)
        outFile.parentFile?.mkdirs()

        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var muxerStarted = false

        try {
            if (inputPath.startsWith("http://") || inputPath.startsWith("https://")) {
                extractor.setDataSource(inputPath, headers)
            } else {
                extractor.setDataSource(inputPath)
            }

            val trackCount = extractor.trackCount
            if (trackCount <= 0) return false

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            if (!audioOnly) {
                val retriever = MediaMetadataRetriever()
                try {
                    if (inputPath.startsWith("http://") || inputPath.startsWith("https://")) {
                        retriever.setDataSource(inputPath, headers)
                    } else {
                        retriever.setDataSource(inputPath)
                    }
                    val rot = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull()
                    if (rot != null && (rot == 0 || rot == 90 || rot == 180 || rot == 270)) {
                        muxer.setOrientationHint(rot)
                    }
                } catch (_: Exception) {
                } finally {
                    try {
                        retriever.release()
                    } catch (_: Exception) {}
                }
            }

            val indexMap = HashMap<Int, Int>()
            var maxBufferSize = 512 * 1024

            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                val isVideo = mime.startsWith("video/")
                val isAudio = mime.startsWith("audio/")

                if (audioOnly && !isAudio) continue
                if (!isVideo && !isAudio) continue

                extractor.selectTrack(i)
                val dstIndex = muxer.addTrack(format)
                indexMap[i] = dstIndex

                if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                    val sz = format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
                    if (sz > maxBufferSize) maxBufferSize = sz
                }
            }

            if (indexMap.isEmpty()) return false

            val startUs = startMs * 1000L
            val endUs = endMs * 1000L
            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val buffer = ByteBuffer.allocate(maxBufferSize)
            val bufferInfo = MediaCodec.BufferInfo()

            muxer.start()
            muxerStarted = true

            var firstSampleUs = -1L

            while (true) {
                bufferInfo.offset = 0
                bufferInfo.size = extractor.readSampleData(buffer, 0)
                if (bufferInfo.size < 0) {
                    bufferInfo.size = 0
                    break
                }

                val sampleTimeUs = extractor.sampleTime
                if (sampleTimeUs < 0) break
                if (sampleTimeUs > endUs) break

                val trackIndex = extractor.sampleTrackIndex
                val dstTrack = indexMap[trackIndex]
                if (dstTrack != null) {
                    if (firstSampleUs < 0) firstSampleUs = sampleTimeUs
                    val adjustedPts = (sampleTimeUs - firstSampleUs).coerceAtLeast(0L)
                    bufferInfo.presentationTimeUs = adjustedPts
                    bufferInfo.flags = extractor.sampleFlags
                    muxer.writeSampleData(dstTrack, buffer, bufferInfo)
                }
                extractor.advance()
            }

            return outFile.exists() && outFile.length() > 0L
        } finally {
            try {
                if (muxerStarted) muxer?.stop()
            } catch (_: Exception) {}
            try {
                muxer?.release()
            } catch (_: Exception) {}
            try {
                extractor.release()
            } catch (_: Exception) {}
        }
    }
}
