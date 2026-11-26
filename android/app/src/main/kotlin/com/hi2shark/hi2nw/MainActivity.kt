package com.hi2shark.hi2nw

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.hi2shark.hi2nw.plugins.AppPlugin
import com.hi2shark.hi2nw.plugins.BatteryPlugin
import com.hi2shark.hi2nw.plugins.LinkPlugin
import com.hi2shark.hi2nw.plugins.ServicePlugin
import com.hi2shark.hi2nw.plugins.TilePlugin
import com.hi2shark.hi2nw.plugins.WifiSsidPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(BatteryPlugin())
        flutterEngine.plugins.add(LinkPlugin())
        flutterEngine.plugins.add(ServicePlugin())
        flutterEngine.plugins.add(TilePlugin())
        flutterEngine.plugins.add(WifiSsidPlugin())
        ServiceState.attachFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        flutterEngine?.let(ServiceState::detachFlutterEngine)
        super.onDestroy()
    }
}
