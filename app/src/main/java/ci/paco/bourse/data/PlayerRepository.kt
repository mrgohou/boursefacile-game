package ci.paco.bourse.data

import android.content.Context
import ci.paco.bourse.domain.Player

class PlayerRepository(context: Context) {
    private val preferences = context.getSharedPreferences("paco.kotlin.save", Context.MODE_PRIVATE)

    fun load(): Player = preferences.getString("player", null)?.let(PlayerCodec::decode) ?: Player()

    fun save(player: Player) {
        check(
            preferences.edit().putString("player", PlayerCodec.encode(player.checked())).commit()
        ) {
            "Écriture impossible. Aucun achat validé."
        }
    }
}
