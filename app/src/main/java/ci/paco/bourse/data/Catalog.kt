package ci.paco.bourse.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class Question(val text: String, val answers: List<String>, val explanation: String)

data class Destination(
    val name: String,
    val country: String,
    val topic: String,
    val intro: String,
    val reminder: String,
    val questions: List<Question>,
)

object Catalog {
    fun load(context: Context): List<Destination> {
        fun read(file: String) =
            context.assets.open("companion/$file.json").bufferedReader().use { it.readText() }
        val cities = JSONArray(read("cities"))
        val quiz = JSONObject(read("quiz"))
        require(cities.length() == 15)
        return (0 until cities.length()).map { i ->
            val city = cities.getJSONObject(i)
            val questions = quiz.getJSONArray("${i+1}")
            require(questions.length() == 3)
            Destination(
                city.getString("name"),
                city.getString("country"),
                city.getString("notion"),
                if (i == 6)
                    "Le PER compare le cours au bénéfice par action. Ce ratio ne promet pas de remboursement."
                else city.getString("pacoIntro"),
                if (i == 6) "PER = cours ÷ BPA positif. Les bénéfices futurs restent incertains."
                else city.getString("retiens"),
                (0..2).map { q ->
                    val item = questions.getJSONObject(q)
                    val a = item.getJSONArray("a")
                    Question(
                        item.getString("q"),
                        (0 until a.length()).map { a.getString(it) },
                        if (i == 6)
                            "Le PER est un ratio de valorisation, pas une durée de remboursement garantie."
                        else item.getString("why"),
                    )
                },
            )
        }
    }
}
