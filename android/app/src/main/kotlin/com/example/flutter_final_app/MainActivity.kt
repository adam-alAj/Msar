package com.example.flutter_final_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.flutter_final_app/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidget") {
                    CheckpointWidgetProvider.triggerUpdate(this)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
