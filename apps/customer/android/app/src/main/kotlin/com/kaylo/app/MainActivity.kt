package com.kaylo.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var prescriptions: PrescriptionDocuments? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prescriptions = PrescriptionDocuments(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kaylo/prescriptions")
            .setMethodCallHandler { call, result -> prescriptions!!.handle(call, result) }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (prescriptions?.onActivityResult(requestCode, resultCode, data) != true) super.onActivityResult(requestCode, resultCode, data)
    }
    override fun onDestroy() { prescriptions?.dispose(); super.onDestroy() }
}
