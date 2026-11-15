package com.example.paco_bourse

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "paco/sources").setMethodCallHandler { call, result ->
            if (call.method == "fluxQuiz") {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://fluxbourse.com/quiz-bourse")))
                    result.success(null)
                } catch (e: Exception) { result.error("browser", "Navigateur indisponible", null) }
            } else result.notImplemented()
        }
    }
}
