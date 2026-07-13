package com.ocp.ocp_v1

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private var platformPlugin: PlatformPlugin? = null

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val plugin = PlatformPlugin(context!!)
        plugin.registerWith(flutterEngine)
        platformPlugin = plugin
    }

    override fun onDestroy() {
        platformPlugin?.dispose()
        platformPlugin = null
        super.onDestroy()
    }
}