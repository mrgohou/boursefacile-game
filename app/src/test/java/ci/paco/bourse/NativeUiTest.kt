package ci.paco.bourse

import android.graphics.Bitmap
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.lifecycle.ViewModelProvider
import ci.paco.bourse.data.PlayerCodec
import ci.paco.bourse.domain.Player
import java.io.File
import java.time.Duration
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.shadows.ShadowSystemClock

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], qualifiers = "w390dp-h844dp-xxhdpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class NativeUiTest {
    @get:Rule val compose = createAndroidComposeRule<MainActivity>()
    private val vm
        get() = ViewModelProvider(compose.activity)[PacoViewModel::class.java]

    private fun ready() {
        compose.waitUntil(15000) { !vm.ui.value.loading }
        compose.waitForIdle()
        compose.waitUntil(15000) {
            compose
                .onAllNodesWithContentDescription("Chargement de la ville")
                .fetchSemanticsNodes()
                .isEmpty()
        }
    }

    private fun capture(name: String, dialog: Boolean = false) {
        val directory = System.getenv("PACO_NATIVE_PREVIEWS") ?: return
        File(directory).mkdirs()
        compose.waitForIdle()
        compose.runOnUiThread {
            // Robolectric has no real display compositor for PixelCopy. Draw
            // the actual Android root view through its native graphics Canvas.
            val root =
                if (dialog) {
                    val type = Class.forName("android.view.WindowManagerGlobal")
                    val instance = type.getDeclaredMethod("getInstance").invoke(null)
                    val field = type.getDeclaredField("mViews").apply { isAccessible = true }
                    @Suppress("UNCHECKED_CAST")
                    (field.get(instance) as List<android.view.View>).last()
                } else compose.activity.window.decorView
            require(root.width > 0 && root.height > 0)
            val image = Bitmap.createBitmap(root.width, root.height, Bitmap.Config.ARGB_8888)
            root.draw(android.graphics.Canvas(image))
            File(directory, "$name.png").outputStream().use {
                image.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            image.recycle()
        }
    }

    @Test
    fun nativeLaunchInstructionsTimeoutAndHome() {
        ready()
        compose.runOnUiThread {
            vm.previewImport(PlayerCodec.encode(Player()))
            vm.confirmImport()
        }
        compose.waitUntil(10000) { !vm.ui.value.busy && vm.ui.value.player.completed.isEmpty() }
        compose.onNodeWithText("Ma ville").assertIsDisplayed()
        capture("native-city")
        compose.onNodeWithText("Jouer").performClick()
        compose.onNodeWithText("Jouer").performClick()
        compose.onNodeWithText("C’est parti").assertIsDisplayed()
        capture("native-instructions", true)
        compose.onNodeWithText("C’est parti").performClick()
        compose.onNodeWithText("Temps restant", substring = true).assertIsDisplayed()
        capture("native-puzzle")
        compose.runOnUiThread {
            ShadowSystemClock.advanceBy(Duration.ofSeconds(61))
            vm.reconcile()
        }
        compose.onNodeWithContentDescription("PAS DE CHANCE").assertExists()
        compose.onNodeWithText("Le temps est écoulé.").assertIsDisplayed()
        capture("native-lose", true)
        compose.onNodeWithText("Menu principal").performClick()
        compose.onNodeWithText("Ma ville").assertIsDisplayed()
        org.junit.Assert.assertEquals(10000, vm.ui.value.player.cash)
    }

    @Test
    fun nativePortfolioTradesPersistAndKeepCards() {
        ready()
        val fixture = Player().win(0).learn(0).win(1).learn(1).trade("cacao", true)
        compose.runOnUiThread {
            vm.previewImport(PlayerCodec.encode(fixture))
            vm.confirmImport()
        }
        compose.waitUntil(10000) { !vm.ui.value.busy && vm.ui.value.player.cards.contains("cacao") }
        compose.onNodeWithText("Propriétés").performClick()
        compose.onNodeWithText("Voir cette action").performClick()
        compose.onNodeWithText("Acheter plus").assertIsDisplayed()
        compose.onNodeWithText("Vendre").assertIsDisplayed()
        capture("native-shares")
        compose.onNodeWithText("Acheter plus").performClick()
        compose.waitUntil(10000) { vm.ui.value.player.holdings["cacao"] == 2 && !vm.ui.value.busy }
        compose.onNodeWithText("Vendre").performClick()
        compose.waitUntil(10000) { vm.ui.value.player.holdings["cacao"] == 1 && !vm.ui.value.busy }
        org.junit.Assert.assertEquals(fixture.cash - 50, vm.ui.value.player.cash)
        org.junit.Assert.assertTrue("cacao" in vm.ui.value.player.cards)
    }

    @Test
    fun nativeConstructionAndJourneyShareOneSavedEconomy() {
        ready()
        val fixture = Player().win(0).learn(0)
        compose.runOnUiThread {
            vm.previewImport(PlayerCodec.encode(fixture))
            vm.confirmImport()
        }
        compose.waitUntil(10000) { !vm.ui.value.busy && vm.ui.value.player.cash == 11500 }
        compose.onNodeWithText("Agrandir").performClick()
        compose.onAllNodesWithText("Acheter le terrain").onFirst().performClick()
        compose.waitUntil(10000) { "rive" in vm.ui.value.player.plots && !vm.ui.value.busy }
        compose.onNodeWithText("Ferme de cacao\n500 FCFA-jeu").performScrollTo().performClick()
        compose.waitUntil(10000) {
            vm.ui.value.player.constructions["rive"] == "ferme" && !vm.ui.value.busy
        }
        compose.onNodeWithText("Accueil").performClick()
        compose.onNodeWithText("Voyager").performClick()
        compose.onAllNodesWithText("Découvrir").onFirst().performClick()
        compose.onNodeWithText("Notion 1 · +300 FCFA-jeu").performScrollTo().performClick()
        compose.onNodeWithText("8").performClick()
        compose.waitUntil(10000) { 0 in vm.ui.value.player.journey && !vm.ui.value.busy }
        org.junit.Assert.assertEquals(10300, vm.ui.value.player.cash)
        compose.onNodeWithText("8").performClick()
        compose.waitForIdle()
        org.junit.Assert.assertEquals(10300, vm.ui.value.player.cash)
    }

    @Test
    fun nativeWinningRoundIsSavedBeforeHome() {
        ready()
        compose.runOnUiThread {
            vm.previewImport(PlayerCodec.encode(Player()))
            vm.confirmImport()
        }
        compose.waitUntil(10000) { !vm.ui.value.busy && vm.ui.value.player.completed.isEmpty() }
        compose.onNodeWithText("Jouer").performClick()
        compose.onNodeWithText("Jouer").performClick()
        compose.onNodeWithText("C’est parti").performClick()
        for (turn in 0..15) {
            if (vm.ui.value.puzzle?.outcome != null) break
            compose.runOnUiThread { vm.hint() }
            val pair = vm.ui.value.puzzle!!.hint.toList()
            org.junit.Assert.assertEquals(2, pair.size)
            for (index in pair) compose
                .onNode(
                    hasContentDescription(
                        "Ligne ${index/7+1}, colonne ${index%7+1},",
                        substring = true,
                    )
                )
                .performClick()
            compose.runOnUiThread {
                org.robolectric.shadows.ShadowLooper.idleMainLooper(
                    3,
                    java.util.concurrent.TimeUnit.SECONDS,
                )
            }
            compose.waitForIdle()
        }
        compose.waitUntil(10000) { vm.ui.value.puzzle?.saved == true }
        compose.onNodeWithContentDescription("GAGNE").assertExists()
        capture("native-win", true)
        org.junit.Assert.assertEquals(11500, vm.ui.value.player.cash)
        compose.onNodeWithText("Menu principal").performClick()
        compose.onNodeWithText("Ma ville").assertIsDisplayed()
        org.junit.Assert.assertEquals(setOf(0), vm.ui.value.player.completed)
    }
}
