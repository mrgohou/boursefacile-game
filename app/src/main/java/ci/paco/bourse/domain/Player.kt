package ci.paco.bourse.domain

/** Offline teaching economy. Construction expenses are not securities. */
data class Company(
    val id: String,
    val name: String,
    val sector: String,
    val price: Int,
    val asset: String,
)

val companies =
    listOf(
        Company("cacao", "Cacao des Lagunes", "Agroalimentaire", 2000, "agro-1"),
        Company("telecom", "Télécom Horizon", "Télécommunications", 2500, "telecom-1"),
        Company("banque", "Banque Baobab", "Banque", 1500, "banque-1"),
    )

data class Land(
    val id: String,
    val name: String,
    val price: Int,
    val gains: Int,
    val x: Float,
    val y: Float,
)

val lands =
    listOf(
        Land("rive", "Les Rives", 1000, 1500, 1450f, 550f),
        Land("verger", "Le Verger", 1500, 3000, 1750f, 730f),
        Land("marche", "Le Marché", 2200, 4500, 1450f, 950f),
        Land("atelier", "Les Ateliers", 3000, 6000, 1130f, 1130f),
        Land("lumiere", "Les Lumières", 4000, 9000, 800f, 1290f),
        Land("jardin", "Le Grand Jardin", 5000, 12000, 470f, 1100f),
    )

data class Building(val id: String, val name: String, val cost: Int, val asset: String)

val buildings =
    listOf(
        Building("ferme", "Ferme de cacao", 500, "agro-1"),
        Building("boutique", "Boutique du quartier", 650, "distribution-1"),
        Building("antenne", "Centre télécom", 800, "telecom-1"),
        Building("banque", "Agence du quartier", 1000, "banque-1"),
        Building("atelier", "Atelier de production", 1200, "industrie-1"),
        Building("energie", "Maison de l’énergie", 1500, "energie-1"),
        Building("services", "Centre de services", 1800, "services-1"),
    )

fun fee(amount: Int) = maxOf(25, (amount + 99) / 100)

data class Player(
    val cash: Int = 10000,
    val holdings: Map<String, Int> = companies.associate { it.id to 0 },
    val completed: Set<Int> = emptySet(),
    val answered: Set<Int> = emptySet(),
    val cards: Set<String> = emptySet(),
    val plots: Set<String> = emptySet(),
    val constructions: Map<String, String> = emptyMap(),
    val journey: Set<Int> = emptySet(),
    val dropped: Boolean = false,
    val dividend: Boolean = false,
    val history: List<String> = emptyList(),
) {
    val unlocked: Int
        get() = (0..5).firstOrNull { it !in answered } ?: 6

    val gains: Int
        get() = completed.size * 1500 + journey.size * 300

    fun price(id: String): Int =
        companies.first { it.id == id }.price -
            if (id == "cacao") (if (dropped) 300 else 0) + (if (dividend) 100 else 0) else 0

    val holdingsValue: Long
        get() = companies.sumOf { (holdings[it.id] ?: 0).toLong() * price(it.id) }

    fun checked(): Player {
        require(cash in 0..1_000_000_000) { "Solde invalide." }
        require(
            holdings.keys == companies.map { it.id }.toSet() &&
                holdings.values.all { it in 0..1_000_000_000 }
        ) {
            "Portefeuille invalide."
        }
        require(completed.all { it in 0..5 } && answered.all { it in completed }) {
            "Progression invalide."
        }
        require(completed.all { it == 0 || it - 1 in answered }) { "Progression non séquentielle." }
        require(
            cards.all { id -> companies.any { it.id == id } } &&
                holdings.all { (id, n) -> n == 0 || id in cards }
        ) {
            "Cartes invalides."
        }
        require(holdings.values.all { it == 0 } || 1 in answered) { "Actions non débloquées." }
        require(!dropped || 2 in answered) { "Marché non débloqué." }
        require(!dividend || (dropped && 4 in answered)) { "Dividende non débloqué." }
        require(
            plots.all { id -> lands.any { it.id == id } } &&
                lands.withIndex().all { (i, l) ->
                    l.id !in plots || (gains >= l.gains && (i == 0 || lands[i - 1].id in plots))
                }
        ) {
            "Terrains invalides."
        }
        require(
            constructions.all { (land, type) -> land in plots && buildings.any { it.id == type } }
        ) {
            "Construction invalide."
        }
        require(
            journey.all { q ->
                q in 0..44 && (q / 3 == 0 || (0..2).all { (q / 3 - 1) * 3 + it in journey })
            }
        ) {
            "Voyage invalide."
        }
        require(history.size <= 50 && history.all { it.length <= 500 }) { "Carnet invalide." }
        return this
    }

    private fun log(message: String) = copy(history = (history + message).takeLast(50)).checked()

    fun win(level: Int): Player {
        require(level in 0..5) { "Niveau inconnu." }
        if (level in completed) return this
        require(level == unlocked) { "Termine la notion précédente." }
        return copy(cash = cash + 1500, completed = completed + level)
            .log("Puzzle ${level+1} : +1 500 FCFA-jeu.")
    }

    fun learn(level: Int): Player {
        require(level in completed) { "Réussis le puzzle avant la notion." }
        if (level in answered) return this
        return copy(answered = answered + level).log("Notion ${level+1} comprise.")
    }

    fun trade(id: String, buy: Boolean): Player {
        require(companies.any { it.id == id }) { "Entreprise inconnue." }
        require(1 in answered) { "Termine les deux premières notions." }
        val amount = price(id)
        val quantity = holdings.getValue(id)
        if (buy) require(cash >= amount + fee(amount)) { "Épargne insuffisante, frais compris." }
        else require(quantity > 0) { "Tu ne détiens aucune part." }
        return copy(
                cash = cash + if (buy) -amount - fee(amount) else amount - fee(amount),
                holdings = holdings + (id to (quantity + if (buy) 1 else -1)),
                cards = if (buy) cards + id else cards,
            )
            .log("${if (buy) "Achat" else "Vente"} $id · frais ${fee(amount)} FCFA-jeu.")
    }

    fun buyLand(id: String): Player {
        val index = lands.indexOfFirst { it.id == id }
        require(index >= 0) { "Terrain inconnu." }
        val land = lands[index]
        require(id !in plots) { "Terrain déjà acquis." }
        require(index == 0 || lands[index - 1].id in plots) { "Acquiers le quartier précédent." }
        require(gains >= land.gains) { "Gagne encore des récompenses." }
        require(cash >= land.price) { "Épargne insuffisante." }
        return copy(cash = cash - land.price, plots = plots + id)
            .log("Terrain ${land.name} : −${land.price} FCFA-jeu.")
    }

    fun build(land: String, type: String): Player {
        require(land in plots && land !in constructions) { "Il faut un terrain acquis et libre." }
        val building = buildings.firstOrNull { it.id == type } ?: error("Bâtiment inconnu.")
        require(cash >= building.cost) { "Épargne insuffisante." }
        return copy(cash = cash - building.cost, constructions = constructions + (land to type))
            .log("Construction ${building.name} : −${building.cost} FCFA-jeu.")
    }

    fun answerJourney(city: Int, question: Int): Player {
        require(city in 0..14 && question in 0..2) { "Notion inconnue." }
        val id = city * 3 + question
        if (id in journey) return this
        require(city == 0 || (0..2).all { (city - 1) * 3 + it in journey }) {
            "Termine la destination précédente."
        }
        return copy(cash = cash + 300, journey = journey + id)
            .log("Voyage ${city+1}, notion ${question+1} : +300 FCFA-jeu.")
    }

    fun drop(): Player {
        if (dropped) return this
        require(2 in answered) { "Termine la notion sur le risque." }
        return copy(dropped = true).log("Scénario : cacao −300 FCFA-jeu par part.")
    }

    fun payDividend(): Player {
        if (dividend) return this
        require(4 in answered && dropped && holdings.getValue("cacao") > 0) {
            "Termine la notion, observe la baisse et détiens une part de cacao."
        }
        val amount = holdings.getValue("cacao").toLong() * 100
        require(amount <= 1_000_000_000L - cash) { "Limite de la simulation atteinte." }
        return copy(dividend = true, cash = cash + amount.toInt())
            .log("Dividende : +100 en cash et −100 au cours, par part.")
    }
}
