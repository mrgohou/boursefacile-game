package ci.paco.bourse.data

import ci.paco.bourse.domain.*
import org.json.JSONArray
import org.json.JSONObject

/** Explicit v4 interchange (reads v1–v3). Never reads another Android app's private files. */
object PlayerCodec {
    fun encode(p: Player): String =
        JSONObject()
            .apply {
                put("version", 4)
                put("cash", p.cash)
                put("holdings", JSONObject(p.holdings))
                put("prices", JSONObject(companies.associate { it.id to p.price(it.id) }))
                put("completed", JSONArray(p.completed.sorted()))
                put("answered", JSONArray(p.answered.sorted()))
                put("companyCards", JSONArray(p.cards.sorted()))
                put("ownedPlots", JSONArray(p.plots.sorted()))
                put("townBuildings", JSONObject(p.constructions))
                put("journeyAnswers", JSONArray(p.journey.sorted()))
                put("marketDropped", p.dropped)
                put("dividendPaid", p.dividend)
                put("history", JSONArray(p.history))
            }
            .toString()

    fun decode(text: String): Player {
        require(text.length <= 131072) { "Sauvegarde trop volumineuse." }
        val j = JSONObject(text)
        require(j.get("version") is Int)
        val version = j.getInt("version")
        require(version in 1..4) { "Version de sauvegarde inconnue." }
        fun strings(key: String): List<String> {
            val a = j.getJSONArray(key)
            return (0 until a.length()).map {
                require(a.get(it) is String)
                a.getString(it)
            }
        }
        fun ids(key: String): Set<Int> {
            val a = j.getJSONArray(key)
            val list =
                (0 until a.length()).map {
                    require(a.get(it) is Int)
                    a.getInt(it)
                }
            require(list.size == list.toSet().size)
            return list.toSet()
        }
        fun stringIds(key: String): Set<String> {
            val list = strings(key)
            require(list.size == list.toSet().size)
            return list.toSet()
        }
        val h = j.getJSONObject("holdings")
        require(h.length() == 3)
        val holding = companies.associate { c ->
            require(h.get(c.id) is Int)
            c.id to h.getInt(c.id)
        }
        require(
            j.get("cash") is Int &&
                j.get("marketDropped") is Boolean &&
                j.get("dividendPaid") is Boolean
        )
        val p =
            Player(
                    cash = j.getInt("cash"),
                    holdings = holding,
                    completed = ids("completed"),
                    answered = ids("answered"),
                    cards =
                        if (version == 1) holding.filterValues { it > 0 }.keys.toSet()
                        else stringIds("companyCards"),
                    plots = if (version >= 3) stringIds("ownedPlots") else emptySet(),
                    constructions =
                        if (version >= 3)
                            j.getJSONObject("townBuildings").let { o ->
                                o.keys().asSequence().associateWith { key ->
                                    require(o.get(key) is String)
                                    o.getString(key)
                                }
                            }
                        else emptyMap(),
                    journey = if (version >= 3) ids("journeyAnswers") else emptySet(),
                    dropped = j.getBoolean("marketDropped"),
                    dividend = j.getBoolean("dividendPaid"),
                    history = strings("history"),
                )
                .checked()
        if (version < 4)
            require(p.completed.all { it in 0..5 } && p.answered.all { it in 0..5 }) {
                "Progression incompatible avec une ancienne sauvegarde."
            }
        val prices = j.getJSONObject("prices")
        require(
            prices.length() == 3 &&
                companies.all { prices.get(it.id) is Int && prices.getInt(it.id) == p.price(it.id) }
        ) {
            "Cours incompatibles."
        }
        return p
    }
}
