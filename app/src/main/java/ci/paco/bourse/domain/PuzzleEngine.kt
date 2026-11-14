package ci.paco.bourse.domain

import kotlin.math.abs
import kotlin.math.min
import kotlin.random.Random

fun secondsFor(level: Int): Int =
    when (level) {
        0,
        1 -> 60
        2 -> 70
        3,
        4 -> 75
        else -> 90
    }

class RoundClock(val seconds: Int) {
    private var deadline: Long? = null

    fun start(now: Long) {
        if (deadline == null) deadline = now + seconds * 1000L
    }

    fun remaining(now: Long): Int =
        deadline?.let { ((it - now + 999) / 1000).coerceIn(0, seconds.toLong()).toInt() } ?: seconds
}

enum class Phase {
    SWAP,
    REVERT,
    CLEAR,
    FALL,
    SHUFFLE,
}

data class Motion(val type: Int, val from: Int, val to: Int)

data class Frame(
    val phase: Phase,
    val before: List<Int>,
    val after: List<Int>,
    val cleared: Set<Int> = emptySet(),
    val motions: List<Motion> = emptyList(),
    val chain: Int = 0,
    val score: Int,
    val moves: Int,
)

class PuzzleEngine(val level: Int, seed: Int = 4701) {
    init {
        require(level in 0..5)
    }

    private val random = Random(seed + level * 137)
    var board: List<Int> = fresh()
        private set

    var score = 0
    var moves = 24 - level
    val target = 650 + level * 140
    val won
        get() = score >= target

    val lost
        get() = moves <= 0 && !won

    companion object {
        fun adjacent(a: Int, b: Int) =
            a in 0..48 && b in 0..48 && abs(a % 7 - b % 7) + abs(a / 7 - b / 7) == 1

        fun matches(board: List<Int>): Set<Int> {
            val found = mutableSetOf<Int>()
            for (y in 0..6) for (x in 0..6) {
                val i = y * 7 + x
                if (x < 5 && board[i] == board[i + 1] && board[i] == board[i + 2]) {
                    var n = x
                    while (n < 7 && board[y * 7 + n] == board[i]) {
                        found.add(y * 7 + n)
                        n++
                    }
                }
                if (y < 5 && board[i] == board[i + 7] && board[i] == board[i + 14]) {
                    var n = y
                    while (n < 7 && board[n * 7 + x] == board[i]) {
                        found.add(n * 7 + x)
                        n++
                    }
                }
            }
            return found.toSet()
        }
    }

    private fun exchange(board: MutableList<Int>, a: Int, b: Int) {
        val v = board[a]
        board[a] = board[b]
        board[b] = v
    }

    private fun hintFor(board: List<Int>): Pair<Int, Int>? {
        val copy = board.toMutableList()
        for (i in 0..48) for (j in listOf(i + 1, i + 7)) if (adjacent(i, j)) {
            exchange(copy, i, j)
            val valid = matches(copy).isNotEmpty()
            exchange(copy, i, j)
            if (valid) return i to j
        }
        return null
    }

    fun hint() = hintFor(board)

    private fun fresh(): List<Int> {
        while (true) {
            val result = mutableListOf<Int>()
            for (i in 0..48) {
                val options =
                    (0..5).filter { v ->
                        !(i % 7 >= 2 && result[i - 1] == v && result[i - 2] == v) &&
                            !(i >= 14 && result[i - 7] == v && result[i - 14] == v)
                    }
                result.add(options[random.nextInt(options.size)])
            }
            if (hintFor(result) != null) return result.toList()
        }
    }

    fun swap(a: Int, b: Int): List<Frame> {
        if (won || lost || !adjacent(a, b)) return emptyList()
        val frames = mutableListOf<Frame>()
        val original = board.toList()
        val work = board.toMutableList()
        exchange(work, a, b)
        frames.add(
            Frame(
                Phase.SWAP,
                original,
                work.toList(),
                motions = listOf(Motion(original[a], a, b), Motion(original[b], b, a)),
                score = score,
                moves = moves,
            )
        )
        var matches = matches(work)
        if (matches.isEmpty()) {
            frames.add(
                Frame(
                    Phase.REVERT,
                    work.toList(),
                    original,
                    motions = listOf(Motion(work[a], a, b), Motion(work[b], b, a)),
                    score = score,
                    moves = moves,
                )
            )
            return frames.toList()
        }
        moves--
        var chain = 1
        while (matches.isNotEmpty()) {
            val before = work.toList()
            score += matches.size * 30 * min(chain, 3)
            val empty = work.toMutableList()
            matches.forEach { empty[it] = -1 }
            frames.add(
                Frame(
                    Phase.CLEAR,
                    before,
                    empty.toList(),
                    cleared = matches,
                    chain = chain,
                    score = score,
                    moves = moves,
                )
            )
            val motions = mutableListOf<Motion>()
            for (x in 0..6) {
                val sources = (6 downTo 0).map { it * 7 + x }.filter { it !in matches }
                for (y in 6 downTo 0) {
                    val n = 6 - y
                    val destination = y * 7 + x
                    val source =
                        if (n < sources.size) sources[n] else x - 7 * (n - sources.size + 1)
                    val type = if (source >= 0) before[source] else random.nextInt(6)
                    work[destination] = type
                    motions.add(Motion(type, source, destination))
                }
            }
            frames.add(
                Frame(
                    Phase.FALL,
                    empty.toList(),
                    work.toList(),
                    motions = motions.toList(),
                    chain = chain,
                    score = score,
                    moves = moves,
                )
            )
            matches = matches(work)
            chain++
        }
        board = work.toList()
        if (!won && !lost && hintFor(board) == null) {
            val before = board
            board = fresh()
            frames.add(Frame(Phase.SHUFFLE, before, board, score = score, moves = moves))
        }
        return frames.toList()
    }
}
