package com.kaylo.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var prescriptions: PrescriptionDocuments? = null
    private var contactPicker: PhoneContactPicker? = null
    private var sos: SosCallCoordinator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            val channel = android.app.NotificationChannel("kaylo_sos", "Kaylo SOS alerts", android.app.NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Trusted-contact SOS call invitations"
            channel.enableVibration(true)
            getSystemService(android.app.NotificationManager::class.java).createNotificationChannel(channel)
        }
        contactPicker = PhoneContactPicker(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kaylo/phone_contacts")
            .setMethodCallHandler { call, result ->
                if (call.method == "pick") contactPicker!!.pick(result) else result.notImplemented()
            }
        prescriptions = PrescriptionDocuments(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kaylo/prescriptions")
            .setMethodCallHandler { call, result -> prescriptions!!.handle(call, result) }
        val coordinator = SosCallCoordinator(this)
        sos = coordinator
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kaylo/sos_calls")
            .setMethodCallHandler(coordinator::handle)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kaylo/sos_call_updates")
            .setStreamHandler(coordinator)
    }
    override fun onResume() { super.onResume(); sos?.onResume() }
    override fun onPause() { sos?.onPause(); super.onPause() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        sos?.onPermissionResult(requestCode)
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (contactPicker?.onActivityResult(requestCode, resultCode, data) == true) return
        if (prescriptions?.onActivityResult(requestCode, resultCode, data) != true) super.onActivityResult(requestCode, resultCode, data)
    }
    override fun onDestroy() { contactPicker?.dispose(); prescriptions?.dispose(); sos?.dispose(); super.onDestroy() }
}
