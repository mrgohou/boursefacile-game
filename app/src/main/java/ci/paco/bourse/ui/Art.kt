package ci.paco.bourse.ui

import android.graphics.BitmapFactory
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun rememberArt(): Map<String, ImageBitmap> {
    val context = LocalContext.current
    val art by
        produceState<Map<String, ImageBitmap>>(emptyMap()) {
            value =
                withContext(Dispatchers.IO) {
                    val names =
                        listOf(
                            "buildings/city-garden.png",
                            "buildings/agro-1.webp",
                            "buildings/telecom-1.webp",
                            "buildings/banque-1.webp",
                            "buildings/services-1.webp",
                            "buildings/distribution-1.webp",
                            "buildings/industrie-1.webp",
                            "buildings/energie-1.webp",
                            "buildings/passant-vert.webp",
                            "buildings/passant-rouge.webp",
                            "paco/confiance.webp",
                            "paco/accueil.webp",
                            "paco/reussir.webp",
                            "paco/reconfort.webp",
                            "paco/expliquer.webp",
                        ) +
                            listOf("cacao", "telephone", "billet", "bidon", "ampoule", "engrenage")
                                .map { "tiles/$it.webp" }
                    names
                        .mapNotNull { name ->
                            runCatching {
                                context.assets.open(name).use {
                                    BitmapFactory.decodeStream(it)?.asImageBitmap()
                                }
                            }
                                .getOrNull()
                                ?.let { name to it }
                        }
                        .toMap()
                }
        }
    return art
}
