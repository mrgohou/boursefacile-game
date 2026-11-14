package ci.paco.bourse.domain

data class Lesson(
    val topic: String,
    val question: String,
    val options: List<String>,
    val answer: Int,
    val explanation: String,
)

val lessons =
    listOf(
        Lesson(
            "Épargner",
            "Les FCFA-jeu sont-ils de l’argent réel ?",
            listOf("Oui, on peut les retirer", "Non, ils servent à apprendre", "Oui, à la banque"),
            1,
            "La simulation utilise une monnaie fictive, sans retrait ni achat réel.",
        ),
        Lesson(
            "Action",
            "Une action représente…",
            listOf(
                "Une part du capital d’une entreprise",
                "Un revenu garanti",
                "Un prêt sans risque",
            ),
            0,
            "Tu détiens une petite part d’une entreprise. Sa valeur peut monter ou baisser.",
        ),
        Lesson(
            "Risque",
            "Quand le cours baisse, une part détenue…",
            listOf("Disparaît", "Vaut moins au prix du marché", "Garantit un bénéfice futur"),
            1,
            "La part reste détenue, mais vaut moins. Une remontée n’est pas garantie.",
        ),
        Lesson(
            "Diversification",
            "Diversifier permet surtout de…",
            listOf(
                "Supprimer toute perte",
                "Garantir un dividende",
                "Réduire la dépendance à une seule entreprise",
            ),
            2,
            "Plusieurs secteurs réduisent une dépendance, sans supprimer tous les risques.",
        ),
        Lesson(
            "Dividende",
            "Dans notre démonstration, au versement du dividende…",
            listOf(
                "Le total augmente automatiquement",
                "Le cours est garanti",
                "Le cash augmente et le cours s’ajuste : total inchangé",
            ),
            2,
            "+100 de cash et −100 sur le cours par part isolent le détachement. Un dividende n’est pas garanti.",
        ),
        Lesson(
            "Patience",
            "Une bonne habitude est de…",
            listOf(
                "Acheter et vendre sans arrêt",
                "Comprendre, diversifier et tenir compte des frais",
                "Tout miser sur une seule entreprise",
            ),
            1,
            "La patience et la compréhension comptent. Les performances ne sont jamais promises.",
        ),
    )
