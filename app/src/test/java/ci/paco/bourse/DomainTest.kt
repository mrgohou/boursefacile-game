package ci.paco.bourse

import ci.paco.bourse.data.PlayerCodec
import ci.paco.bourse.domain.*
import org.junit.Assert.*
import org.junit.Test

class DomainTest {
    private fun taught(): Player = Player().win(0).learn(0).win(1).learn(1)

    @Test
    fun `native game starts with stable deterministic playable boards`() {
        for (level in 0..5) for (seed in 0..15) {
            val a = PuzzleEngine(level, seed)
            val b = PuzzleEngine(level, seed)
            assertEquals(a.board, b.board)
            assertEquals(49, a.board.size)
            assertTrue(PuzzleEngine.matches(a.board).isEmpty())
            assertNotNull(a.hint())
        }
    }

    @Test
    fun `invalid swaps return freely and valid swaps animate real gravity`() {
        for (level in 0..5) {
            val e = PuzzleEngine(level)
            val before = e.board
            val moves = e.moves
            val hint = e.hint()!!
            val frames = e.swap(hint.first, hint.second)
            assertEquals(moves - 1, e.moves)
            assertTrue(e.score > 0)
            assertEquals(before, frames.first().before)
            assertEquals(e.board, frames.last().after)
            frames.zipWithNext().forEach { (a, b) -> assertEquals(a.after, b.before) }
            frames
                .filter { it.phase == Phase.FALL }
                .forEach { frame ->
                    assertEquals((0..48).toSet(), frame.motions.map { it.to }.toSet())
                    frame.motions
                        .filter { it.from >= 0 }
                        .forEach {
                            assertEquals(it.from % 7, it.to % 7)
                            assertTrue(it.to >= it.from)
                            assertEquals(frame.before[it.from], it.type)
                        }
                }
            assertTrue(PuzzleEngine.matches(e.board).isEmpty())
        }
        val e = PuzzleEngine(0)
        var invalid = false
        for (a in 0..48) {
            for (b in listOf(a + 1, a + 7)) {
                if (!PuzzleEngine.adjacent(a, b)) continue
                val attempt = PuzzleEngine(0)
                val frames = attempt.swap(a, b)
                if (frames.lastOrNull()?.phase == Phase.REVERT) {
                    assertEquals(24, attempt.moves)
                    assertEquals(0, attempt.score)
                    assertEquals(e.board, attempt.board)
                    invalid = true
                    break
                }
            }
            if (invalid) break
        }
        assertTrue(invalid)
    }

    @Test
    fun `out of bounds gestures never wrap board rows`() {
        assertFalse(PuzzleEngine.adjacent(6, 7))
        assertFalse(PuzzleEngine.adjacent(0, -1))
        assertTrue(PuzzleEngine.adjacent(0, 7))
        val e = PuzzleEngine(0)
        assertTrue(e.swap(6, 7).isEmpty())
        assertEquals(24, e.moves)
    }

    @Test
    fun `time budgets and monotonic deadlines cannot be restarted`() {
        assertEquals(listOf(60, 60, 70, 75, 75, 90), (0..5).map(::secondsFor))
        val clock = RoundClock(60)
        assertEquals(60, clock.remaining(500000))
        clock.start(500000)
        assertEquals(1, clock.remaining(559999))
        clock.start(559999)
        assertEquals(0, clock.remaining(560000))
        assertEquals(0, clock.remaining(900000))
    }

    @Test
    fun `rewards and learning remain sequential and unique`() {
        val a = Player().win(0)
        assertEquals(11500, a.cash)
        assertSame(a, a.win(0))
        assertThrows(IllegalArgumentException::class.java) { a.win(1) }
        val b = a.learn(0).win(1).learn(1)
        assertEquals(13000, b.cash)
        assertSame(b, b.learn(1))
    }

    @Test
    fun `trading uses fees and keeps permanent cards`() {
        val a = taught()
        val bought = a.trade("cacao", true)
        assertEquals(a.cash - 2025, bought.cash)
        assertEquals(1, bought.holdings["cacao"])
        val sold = bought.trade("cacao", false)
        assertEquals(a.cash - 50, sold.cash)
        assertEquals(0, sold.holdings["cacao"])
        assertTrue("cacao" in sold.cards)
        assertThrows(IllegalArgumentException::class.java) { sold.trade("cacao", false) }
        assertThrows(IllegalArgumentException::class.java) { Player().trade("cacao", true) }
    }

    @Test
    fun `land and construction require gains budget ownership and order`() {
        assertThrows(IllegalArgumentException::class.java) { Player().buyLand("rive") }
        val a = Player().win(0)
        assertThrows(IllegalArgumentException::class.java) { a.buyLand("verger") }
        val land = a.buyLand("rive")
        assertEquals(10500, land.cash)
        assertThrows(IllegalArgumentException::class.java) { land.buyLand("rive") }
        val built = land.build("rive", "ferme")
        assertEquals(10000, built.cash)
        assertEquals("ferme", built.constructions["rive"])
        assertThrows(IllegalArgumentException::class.java) { built.build("rive", "boutique") }
        assertThrows(IllegalArgumentException::class.java) { a.build("rive", "ferme") }
    }

    @Test
    fun `journey rewards are unique and the maximum town stays attainable`() {
        var p = Player()
        assertThrows(IllegalArgumentException::class.java) { p.answerJourney(1, 0) }
        for (i in 0..5) p = p.win(i).learn(i)
        for (c in 0..14) for (q in 0..2) p = p.answerJourney(c, q)
        val once = p
        assertSame(p, p.answerJourney(0, 0))
        assertEquals(32500, p.cash)
        for (land in lands) p = p.buyLand(land.id).build(land.id, "services")
        assertEquals(6, p.constructions.size)
        assertEquals(5000, p.cash)
        assertEquals(22500, p.gains)
        assertEquals(45, once.journey.size)
    }

    @Test
    fun `dividend detachment does not increase total wealth`() {
        var p = taught().trade("cacao", true)
        for (i in 2..4) p = p.win(i).learn(i)
        val before = p.drop()
        val after = before.payDividend()
        assertEquals(before.cash + 100, after.cash)
        assertEquals(before.price("cacao") - 100, after.price("cacao"))
        assertEquals(before.cash + before.holdingsValue, after.cash + after.holdingsValue)
        assertSame(after, after.payDividend())
    }

    @Test
    fun `save v3 roundtrip and legacy migration preserve value`() {
        val p =
            taught().trade("cacao", true).buyLand("rive").build("rive", "ferme").answerJourney(0, 0)
        val json = PlayerCodec.encode(p)
        assertEquals(p, PlayerCodec.decode(json))
        val legacy =
            org.json.JSONObject(PlayerCodec.encode(taught().trade("cacao", true))).apply {
                put("version", 1)
                remove("companyCards")
                remove("ownedPlots")
                remove("townBuildings")
                remove("journeyAnswers")
            }
        val migrated = PlayerCodec.decode(legacy.toString())
        assertEquals(10975, migrated.cash)
        assertTrue("cacao" in migrated.cards)
        assertTrue(migrated.plots.isEmpty())
    }

    @Test
    fun `malformed imports cannot create orphan buildings or phantom cards`() {
        val valid = org.json.JSONObject(PlayerCodec.encode(taught().trade("cacao", true)))
        val missingCard =
            org.json.JSONObject(valid.toString()).apply {
                put("companyCards", org.json.JSONArray())
            }
        assertThrows(IllegalArgumentException::class.java) {
            PlayerCodec.decode(missingCard.toString())
        }
        val orphan =
            org.json.JSONObject(valid.toString()).apply {
                put("townBuildings", org.json.JSONObject(mapOf("rive" to "ferme")))
            }
        assertThrows(IllegalArgumentException::class.java) { PlayerCodec.decode(orphan.toString()) }
        assertThrows(IllegalArgumentException::class.java) {
            PlayerCodec.decode("x".repeat(131073))
        }
    }

    @Test
    fun `terminal boards never spend another move`() {
        val e = PuzzleEngine(0)
        val pair = e.hint()!!
        e.score = e.target
        e.swap(pair.first, pair.second)
        assertEquals(24, e.moves)
        e.score = 0
        e.moves = 0
        assertTrue(e.swap(pair.first, pair.second).isEmpty())
    }

    @Test
    fun `all thirty stages are configured from the shared catalogue and solvable`() {
        val data =
            org.json
                .JSONObject(java.io.File("src/main/assets/progression/stages.json").readText())
                .getJSONArray("stages")
        assertEquals(30, TOTAL_STAGES)
        assertEquals(TOTAL_STAGES, lessons.size)
        assertEquals(TOTAL_STAGES, data.length())
        for (i in stageSpecs.indices) {
            val spec = stageSpecs[i]
            val e = PuzzleEngine(i)
            val raw = data.getJSONObject(i)
            assertEquals(raw.getInt("target"), e.target)
            assertEquals(raw.getInt("moves"), e.moves)
            assertEquals(raw.getInt("seconds"), secondsFor(i))
            assertTrue(e.target <= e.moves * 90)
            assertTrue(e.moves in 19..24)
            assertTrue(secondsFor(i) in 60..90)
            assertTrue(lessons[i].question.isNotEmpty())
            assertTrue(lessons[i].answer in lessons[i].options.indices)
            val budget = e.moves
            for (turn in 0 until budget) {
                if (e.won) break
                val pair = e.hint()!!
                e.swap(pair.first, pair.second)
            }
            assertTrue("Stage ${i+1} is solvable", e.won)
        }
    }

    @Test
    fun `legacy stage six unlocks seven and v4 preserves thirty unique rewards`() {
        var p = Player()
        for (i in 0..5) p = p.win(i).learn(i)
        val legacy = org.json.JSONObject(PlayerCodec.encode(p)).put("version", 3)
        p = PlayerCodec.decode(legacy.toString())
        assertEquals(6, p.unlocked)
        assertEquals(19000, p.cash)
        assertSame(p, p.win(5))
        for (i in 6 until TOTAL_STAGES) {
            p = p.win(i).learn(i)
            p = PlayerCodec.decode(PlayerCodec.encode(p))
        }
        assertEquals(30, p.unlocked)
        assertEquals(55000, p.cash)
        assertEquals(30, p.completed.size)
        assertThrows(IllegalArgumentException::class.java) { p.win(30) }
        assertThrows(IllegalArgumentException::class.java) {
            PlayerCodec.decode(
                org.json.JSONObject(PlayerCodec.encode(p)).put("version", 3).toString()
            )
        }
    }
}
