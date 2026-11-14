package ci.paco.bourse.data

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool

/** Android media APIs only. Audio errors never prevent the game from opening. */
class GameAudio(private val context: Context) {
    private val preferences =
        context.getSharedPreferences("paco.kotlin.audio", Context.MODE_PRIVATE)
    var musicEnabled = preferences.getBoolean("music", true)
        private set

    var sfxEnabled = preferences.getBoolean("sfx", true)
        private set

    private val pool =
        SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .build()
    private val sounds = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private var music: MediaPlayer? = null
    private var scene = ""
    private var foreground = true

    init {
        pool.setOnLoadCompleteListener { _, id, status -> if (status == 0) ready.add(id) }
        listOf("select", "swap", "invalid", "match", "cascade", "win", "lose", "shuffle", "ui")
            .forEach { event ->
                runCatching {
                    context.assets.openFd("audio/$event.wav").use {
                        sounds[event] = pool.load(it, 1)
                    }
                }
            }
    }

    fun play(event: String) {
        val id = sounds[event] ?: return
        if (sfxEnabled && foreground && id in ready)
            runCatching { pool.play(id, .65f, .65f, 1, 0, 1f) }
    }

    fun scene(next: String) {
        if (scene == next && music != null) return
        scene = next
        restart()
    }

    private fun restart() {
        runCatching { music?.release() }
        music = null
        if (!foreground || !musicEnabled || scene.isEmpty()) return
        runCatching {
            val player = MediaPlayer()
            music = player
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            context.assets.openFd("audio/$scene.wav").use {
                player.setDataSource(it.fileDescriptor, it.startOffset, it.length)
            }
            player.isLooping = true
            player.setVolume(.22f, .22f)
            player.setOnPreparedListener {
                if (music === it && foreground && musicEnabled) it.start()
            }
            player.setOnErrorListener { p, _, _ ->
                if (music === p) {
                    music = null
                    runCatching { p.release() }
                }
                true
            }
            player.prepareAsync()
        }
            .onFailure {
                runCatching { music?.release() }
                music = null
            }
    }

    fun foreground(active: Boolean) {
        foreground = active
        if (active) restart()
        else {
            runCatching { music?.release() }
            music = null
            pool.autoPause()
        }
    }

    fun toggleMusic() {
        musicEnabled = !musicEnabled
        preferences.edit().putBoolean("music", musicEnabled).apply()
        restart()
    }

    fun toggleSfx() {
        sfxEnabled = !sfxEnabled
        preferences.edit().putBoolean("sfx", sfxEnabled).apply()
        if (!sfxEnabled) pool.autoPause()
    }

    fun close() {
        runCatching { music?.release() }
        pool.release()
    }
}
