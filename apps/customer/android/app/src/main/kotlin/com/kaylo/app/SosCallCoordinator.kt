package com.kaylo.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telecom.TelecomManager
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.telephony.SubscriptionManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** A SIM call queue. Never launches another call while Kaylo is in the background. */
class SosCallCoordinator(private val activity: MainActivity) : EventChannel.StreamHandler {
    private data class Contact(val name: String, val phone: String)
    private val handler = Handler(Looper.getMainLooper())
    private fun telephony(): TelephonyManager {
        val manager = activity.getSystemService(TelephonyManager::class.java)
            ?: throw IllegalStateException("This device has no phone service.")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val voiceSim = SubscriptionManager.getDefaultVoiceSubscriptionId()
            if (voiceSim >= 0) return manager.createForSubscriptionId(voiceSim)
        }
        return manager
    }
    private fun telecom(): TelecomManager = activity.getSystemService(TelecomManager::class.java)
        ?: throw IllegalStateException("This device has no phone service.")
    private val permissions = arrayOf(Manifest.permission.CALL_PHONE, Manifest.permission.READ_PHONE_STATE)
    private var sink: EventChannel.EventSink? = null
    private var pending: MethodChannel.Result? = null
    private var contacts = emptyList<Contact>()
    private var attempted = 0
    private var skipped = 0
    private var status = "idle"
    private var error: String? = null
    private var foreground = false
    private var observedCall = false
    private var registeredManager: TelephonyManager? = null
    private var modernListener: TelephonyCallback? = null
    private var legacyListener: PhoneStateListener? = null
    private val nextCall = Runnable { if (foreground && status == "waiting") placeNext() }
    // A call that never starts (no SIM, flight mode, a dismissed SIM chooser)
    // changes no call state, so without this the queue would wait for ever.
    private val stalledCall = Runnable {
        if (foreground && status == "calling" && !observedCall && !runCatching { telecom().isInCall }.getOrDefault(false)) {
            if (attempted >= contacts.size) stop("finished")
            else { status = "waiting"; emit(); placeNext() }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        emit()
    }
    override fun onCancel(arguments: Any?) { sink = null }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> start(call, result)
            "stop" -> {
                pending?.error("cancelled", "The SOS call sequence was cancelled.", null)
                pending = null
                stop("stopped")
                result.success(snapshot())
            }
            else -> result.notImplemented()
        }
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        if (pending != null || status == "calling" || status == "waiting") {
            result.error("busy", "An SOS call sequence is already running.", null)
            return
        }
        val raw = call.argument<List<Map<String, String>>>("contacts") ?: emptyList()
        val parsed = raw.map { Contact(it["name"] ?: "", (it["phone"] ?: "").replace(Regex("[\\s()\\-]"), "")) }
        // One mistyped number must not hold up the rest, so unusable ones are
        // skipped. Three digits is enough: 112 and 108 are real numbers.
        val usable = parsed.filter { Regex("\\+?[0-9]{3,15}").matches(it.phone) }
        if (usable.isEmpty()) {
            result.error("invalid-number", "Check the saved contacts' phone numbers before calling.", null)
            return
        }
        contacts = usable.distinctBy { it.phone.removePrefix("+91").removePrefix("0091").removePrefix("0") }
        skipped = parsed.size - usable.size
        attempted = 0
        error = null
        observedCall = false
        pending = result
        if (permissions.any { activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }) {
            activity.requestPermissions(permissions, REQUEST_CODE)
        } else begin()
    }

    fun onPermissionResult(requestCode: Int) {
        if (requestCode != REQUEST_CODE || pending == null) return
        if (permissions.any { activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }) {
            pending?.error("permission-denied", "Allow phone and phone-state permissions to call your SOS contacts.", null)
            pending = null
            contacts = emptyList()
        } else begin()
    }

    private fun begin() {
        try {
            if (!activity.packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
                throw IllegalStateException("This device cannot make SIM calls.")
            }
            if (telecom().isInCall) throw IllegalStateException("Finish the current phone call before starting SOS.")
            registerListener()
            status = "waiting"
            placeNext()
            if (status == "failed") pending?.error("call-unavailable", error, null)
            else pending?.success(snapshot())
        } catch (exception: Exception) {
            stop("failed", exception.message ?: "The phone call could not be started.")
            pending?.error("call-unavailable", error, null)
        } finally { pending = null }
    }

    private fun registerListener() {
        unregisterListener()
        val manager = telephony()
        registeredManager = manager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val listener = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) { onCallState(state) }
            }
            modernListener = listener
            manager.registerTelephonyCallback(activity.mainExecutor, listener)
        } else {
            @Suppress("DEPRECATION")
            val listener = object : PhoneStateListener() {
                override fun onCallStateChanged(state: Int, number: String?) { onCallState(state) }
            }
            legacyListener = listener
            @Suppress("DEPRECATION")
            manager.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    private fun onCallState(state: Int) {
        if (status != "calling" && status != "waiting") return
        when (state) {
            TelephonyManager.CALL_STATE_OFFHOOK -> observedCall = true
            TelephonyManager.CALL_STATE_RINGING -> stop("stopped", "An incoming call interrupted the SOS sequence.")
            TelephonyManager.CALL_STATE_IDLE -> if (observedCall) {
                observedCall = false
                if (attempted >= contacts.size) stop("finished")
                else { status = "waiting"; emit(); scheduleNext() }
            }
        }
    }

    private fun placeNext() {
        handler.removeCallbacks(nextCall)
        handler.removeCallbacks(stalledCall)
        if (!foreground) return
        try {
            if (telecom().isInCall) return
            if (attempted >= contacts.size) { stop("finished"); return }
            val contact = contacts[attempted]
            observedCall = false
            status = "calling"
            activity.startActivity(Intent(Intent.ACTION_CALL, Uri.fromParts("tel", contact.phone, null)))
            attempted += 1
            emit()
            handler.postDelayed(stalledCall, 6000)
        } catch (exception: Exception) {
            stop("failed", exception.message ?: "The call could not be started. Check your SIM and phone permissions.")
        }
    }

    fun onResume() {
        foreground = true
        scheduleNext()
        handler.removeCallbacks(stalledCall)
        if (status == "calling" && !observedCall) handler.postDelayed(stalledCall, 4000)
    }
    fun onPause() { foreground = false; handler.removeCallbacks(nextCall); handler.removeCallbacks(stalledCall) }
    private fun scheduleNext() {
        handler.removeCallbacks(nextCall)
        if (foreground && status == "waiting") handler.postDelayed(nextCall, 3000)
    }

    private fun snapshot(): Map<String, Any?> = mapOf(
        "status" to status, "attempted" to attempted, "total" to contacts.size,
        "name" to contacts.getOrNull(if (status == "waiting") attempted else attempted - 1)?.name,
        "skipped" to skipped, "error" to error,
    )
    private fun emit() { sink?.success(snapshot()) }
    private fun stop(nextStatus: String, message: String? = null) {
        handler.removeCallbacks(nextCall)
        handler.removeCallbacks(stalledCall)
        status = nextStatus
        error = message
        unregisterListener()
        emit()
    }
    private fun unregisterListener() {
        val manager = registeredManager
        registeredManager = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) modernListener?.let { runCatching { manager?.unregisterTelephonyCallback(it) } }
        modernListener = null
        @Suppress("DEPRECATION")
        legacyListener?.let { runCatching { manager?.listen(it, PhoneStateListener.LISTEN_NONE) } }
        legacyListener = null
    }
    fun dispose() { stop("stopped"); pending?.error("closed", "The SOS screen was closed.", null); pending = null; sink = null }
    companion object { private const val REQUEST_CODE = 701 }
}
