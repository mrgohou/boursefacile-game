package ci.paco.bourse

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.ViewModelProvider
import ci.paco.bourse.ui.PacoApp

class MainActivity : ComponentActivity() {
    private lateinit var game: PacoViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        game = ViewModelProvider(this)[PacoViewModel::class.java]
        setContent { PacoApp(game) }
    }

    override fun onStart() {
        super.onStart()
        if (::game.isInitialized) {
            game.audio.foreground(true)
            game.reconcile()
        }
    }

    override fun onStop() {
        if (::game.isInitialized) game.audio.foreground(false)
        super.onStop()
    }
}
