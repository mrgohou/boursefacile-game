package ci.paco.bourse

import android.app.Application
import android.os.SystemClock
import android.provider.Settings
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import ci.paco.bourse.data.*
import ci.paco.bourse.domain.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

enum class Screen {
    HOME,
    LEVELS,
    PUZZLE,
    PROPERTIES,
    CARDS,
    COMPANY,
    GROWTH,
    JOURNEY,
    SETTINGS,
    HISTORY,
}

data class PuzzleUi(
    val level: Int,
    val board: List<Int>,
    val score: Int,
    val moves: Int,
    val target: Int,
    val remaining: Int,
    val started: Boolean = false,
    val selected: Int? = null,
    val hint: Set<Int> = emptySet(),
    val busy: Boolean = false,
    val frame: Frame? = null,
    val sequence: Int = 0,
    val outcome: String? = null,
    val reason: String = "",
    val saving: Boolean = false,
    val saved: Boolean = false,
)

data class UiState(
    val player: Player = Player(),
    val loading: Boolean = true,
    val error: String? = null,
    val busy: Boolean = false,
    val screen: Screen = Screen.HOME,
    val company: String = "cacao",
    val destinations: List<Destination> = emptyList(),
    val puzzle: PuzzleUi? = null,
    val lesson: Int? = null,
    val message: String? = null,
    val focusLand: String? = null,
    val music: Boolean = true,
    val sfx: Boolean = true,
    val importDraft: Player? = null,
)

class PacoViewModel(app: Application) : AndroidViewModel(app) {
    private val repository = PlayerRepository(app)
    private val mutex = Mutex()
    val audio = GameAudio(app)
    private val _ui = MutableStateFlow(UiState(music = audio.musicEnabled, sfx = audio.sfxEnabled))
    val ui = _ui.asStateFlow()
    private var engine: PuzzleEngine? = null
    private var clock: RoundClock? = null
    private var timer: Job? = null
    private var turn: Job? = null
    val reducedMotion
        get() =
            Settings.Global.getFloat(
                getApplication<Application>().contentResolver,
                Settings.Global.ANIMATOR_DURATION_SCALE,
                1f,
            ) == 0f

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _ui.update { it.copy(loading = true, error = null) }
            runCatching {
                withContext(Dispatchers.IO) {
                    repository.load() to Catalog.load(getApplication())
                }
            }
                .onSuccess { (player, data) ->
                    _ui.update { it.copy(player = player, destinations = data, loading = false) }
                }
                .onFailure {
                    _ui.update {
                        it.copy(
                            loading = false,
                            error = "Impossible de lire la sauvegarde. Elle n’a pas été écrasée.",
                        )
                    }
                }
            audio.scene("city")
        }
    }

    private suspend fun transact(action: (Player) -> Player): Boolean = mutex.withLock {
        if (_ui.value.loading || _ui.value.error != null) return@withLock false
        _ui.update { it.copy(busy = true) }
        try {
            val before = _ui.value.player
            val next = action(before).checked()
            if (next != before) withContext(Dispatchers.IO) { repository.save(next) }
            _ui.update { it.copy(player = next) }
            true
        } catch (e: Exception) {
            _ui.update { it.copy(message = e.message ?: "Écriture impossible. Réessaie.") }
            false
        } finally {
            _ui.update { it.copy(busy = false) }
        }
    }

    private fun change(action: (Player) -> Player, success: () -> Unit = {}) {
        if (_ui.value.busy) return
        viewModelScope.launch { if (transact(action)) success() }
    }

    fun clearMessage() {
        _ui.update { it.copy(message = null) }
    }

    fun navigate(screen: Screen, company: String = _ui.value.company) {
        if (_ui.value.busy) return
        if (screen != Screen.PUZZLE) {
            timer?.cancel()
            turn?.cancel()
            engine = null
            clock = null
        }
        _ui.update {
            it.copy(
                screen = screen,
                company = company,
                puzzle = if (screen == Screen.PUZZLE) it.puzzle else null,
                lesson = null,
            )
        }
        audio.scene(if (screen == Screen.PUZZLE) "puzzle" else "city")
        audio.play("ui")
    }

    fun trade(buy: Boolean) = change({ it.trade(_ui.value.company, buy) }) { audio.play("win") }

    fun buyLand(id: String) =
        change({ it.buyLand(id) }) {
            _ui.update { it.copy(focusLand = id) }
            audio.play("win")
        }

    fun build(land: String, type: String) =
        change({ it.build(land, type) }) {
            _ui.update { it.copy(focusLand = land) }
            audio.play("win")
        }

    fun drop() = change({ it.drop() })

    fun dividend() = change({ it.payDividend() })

    fun learn(level: Int) =
        change({ it.learn(level) }) {
            _ui.update { it.copy(lesson = null, screen = Screen.LEVELS) }
            audio.scene("city")
        }

    fun answerJourney(city: Int, q: Int) =
        change({ it.answerJourney(city, q) }) { audio.play("win") }

    fun dismissLesson() {
        _ui.update { it.copy(lesson = null) }
    }

    fun openLevel(level: Int) {
        if (_ui.value.busy || level !in stageSpecs.indices || level > _ui.value.player.unlocked)
            return
        if (level in _ui.value.player.completed && level !in _ui.value.player.answered) {
            _ui.update { it.copy(lesson = level) }
            return
        }
        timer?.cancel()
        turn?.cancel()
        val next = PuzzleEngine(level)
        engine = next
        clock = RoundClock(secondsFor(level))
        _ui.update {
            it.copy(
                screen = Screen.PUZZLE,
                puzzle =
                    PuzzleUi(
                        level,
                        next.board,
                        next.score,
                        next.moves,
                        next.target,
                        secondsFor(level),
                    ),
            )
        }
        audio.scene("puzzle")
    }

    fun startRound() {
        val p = _ui.value.puzzle ?: return
        if (p.started || p.outcome != null) return
        clock?.start(SystemClock.elapsedRealtime())
        _ui.update { it.copy(puzzle = p.copy(started = true)) }
        timer = viewModelScope.launch {
            while (isActive) {
                tick()
                delay(150)
            }
        }
    }

    private fun tick() {
        val p = _ui.value.puzzle ?: return
        val e = engine ?: return
        if (!p.started || p.outcome != null) return
        val remaining = clock?.remaining(SystemClock.elapsedRealtime()) ?: p.remaining
        if (remaining == 0) {
            finish(e.won, if (e.won) "Objectif atteint !" else "Le temps est écoulé.")
        } else if (remaining != p.remaining)
            _ui.update { it.copy(puzzle = it.puzzle?.copy(remaining = remaining)) }
    }

    fun reconcile() {
        tick()
    }

    private fun accepts(): Boolean {
        val p = _ui.value.puzzle ?: return false
        return p.started &&
            p.outcome == null &&
            !p.busy &&
            (clock?.remaining(SystemClock.elapsedRealtime()) ?: 0) > 0
    }

    fun select(index: Int) {
        if (!accepts() || index !in 0..48) return
        val first = _ui.value.puzzle?.selected
        if (first == null) {
            _ui.update { it.copy(puzzle = it.puzzle?.copy(selected = index, hint = emptySet())) }
            audio.play("select")
        } else if (first == index) _ui.update { it.copy(puzzle = it.puzzle?.copy(selected = null)) }
        else if (PuzzleEngine.adjacent(first, index)) swap(first, index)
        else _ui.update { it.copy(puzzle = it.puzzle?.copy(selected = index)) }
    }

    fun hint() {
        if (!accepts()) return
        val pair = engine?.hint() ?: return
        _ui.update { it.copy(puzzle = it.puzzle?.copy(hint = setOf(pair.first, pair.second))) }
        audio.play("select")
    }

    fun swap(a: Int, b: Int) {
        if (!accepts()) return
        val e = engine ?: return
        val frames = e.swap(a, b)
        if (frames.isEmpty()) return
        _ui.update {
            it.copy(puzzle = it.puzzle?.copy(busy = true, selected = null, hint = emptySet()))
        }
        turn = viewModelScope.launch {
            for (frame in frames) {
                if (engine !== e || _ui.value.puzzle?.outcome != null) return@launch
                _ui.update {
                    it.copy(
                        puzzle =
                            it.puzzle?.copy(
                                board = frame.before,
                                frame = frame,
                                sequence = it.puzzle.sequence + 1,
                                score = frame.score,
                                moves = frame.moves,
                            )
                    )
                }
                audio.play(
                    when (frame.phase) {
                        Phase.SWAP -> "swap"
                        Phase.REVERT -> "invalid"
                        Phase.CLEAR -> if (frame.chain > 1) "cascade" else "match"
                        Phase.SHUFFLE -> "shuffle"
                        else -> "ui"
                    }
                )
                delay(
                    if (reducedMotion) 12
                    else
                        when (frame.phase) {
                            Phase.SWAP,
                            Phase.REVERT -> 150
                            Phase.CLEAR -> 160
                            Phase.FALL -> 220
                            Phase.SHUFFLE -> 240
                        }
                )
            }
            if (engine !== e || _ui.value.puzzle?.outcome != null) return@launch
            _ui.update {
                it.copy(
                    puzzle =
                        it.puzzle?.copy(
                            board = e.board,
                            frame = null,
                            busy = false,
                            score = e.score,
                            moves = e.moves,
                        )
                )
            }
            if (e.won || e.lost)
                finish(e.won, if (e.won) "Objectif atteint !" else "Tu n’as plus de coups.")
        }
    }

    private fun finish(won: Boolean, reason: String) {
        val p = _ui.value.puzzle ?: return
        val e = engine ?: return
        if (p.outcome != null) return
        timer?.cancel()
        _ui.update {
            it.copy(
                puzzle =
                    it.puzzle?.copy(
                        outcome = if (won) "GAGNE" else "PAS DE CHANCE",
                        reason = reason,
                        busy = false,
                        frame = null,
                        board = e.board,
                        score = e.score,
                        moves = e.moves,
                        remaining = clock?.remaining(SystemClock.elapsedRealtime()) ?: p.remaining,
                        saving = won,
                    )
            )
        }
        audio.play(if (won) "win" else "lose")
        if (won) saveWin(e)
    }

    private fun saveWin(e: PuzzleEngine) {
        viewModelScope.launch {
            val success = transact { it.win(e.level) }
            if (engine === e)
                _ui.update { it.copy(puzzle = it.puzzle?.copy(saving = false, saved = success)) }
        }
    }

    fun retrySave() {
        val e = engine ?: return
        val p = _ui.value.puzzle ?: return
        if (p.saving || p.saved || !e.won) return
        _ui.update { it.copy(puzzle = p.copy(saving = true)) }
        saveWin(e)
    }

    fun resultLesson() {
        val p = _ui.value.puzzle ?: return
        if (!p.saved) return
        timer?.cancel()
        turn?.cancel()
        engine = null
        clock = null
        _ui.update { it.copy(screen = Screen.LEVELS, puzzle = null, lesson = p.level) }
        audio.scene("city")
    }

    fun retryRound() {
        val level = _ui.value.puzzle?.level ?: return
        openLevel(level)
    }

    fun toggleMusic() {
        audio.toggleMusic()
        _ui.update { it.copy(music = audio.musicEnabled) }
    }

    fun toggleSfx() {
        audio.toggleSfx()
        _ui.update { it.copy(sfx = audio.sfxEnabled) }
    }

    fun exportSave() = PlayerCodec.encode(_ui.value.player)

    fun previewImport(text: String) {
        runCatching { PlayerCodec.decode(text) }
            .onSuccess { p -> _ui.update { it.copy(importDraft = p) } }
            .onFailure {
                _ui.update {
                    it.copy(
                        message = "Sauvegarde incompatible ou invalide. Aucun changement effectué."
                    )
                }
            }
    }

    fun cancelImport() {
        _ui.update { it.copy(importDraft = null) }
    }

    fun confirmImport() {
        val p = _ui.value.importDraft ?: return
        change({ p }) { _ui.update { it.copy(importDraft = null, screen = Screen.HOME) } }
    }

    override fun onCleared() {
        audio.close()
        super.onCleared()
    }
}
